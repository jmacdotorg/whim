package Whim::Core;

use warnings;
use strict;
use v5.24;

use Moo;
use DBI;
use Path::Tiny;
use Scalar::Util qw(blessed);
use DateTime::Format::ISO8601;
use LWP::UserAgent;
use Digest::SHA qw(sha256_hex);

use lib '/Users/jmac/Documents/Plerd/indieweb/webmention-perl/lib';

use Whim::Mention;

# Specifying $TRANSIENT_DB for data_directory tells SQLite to use an in-memory database rather than persist to disk.
# Helpful for automated tests and maybe future non-persistent uses of whim
our $TRANSIENT_DB = ":memory:";

has 'home' => (
    is       => 'rw',
    required => 1,
    coerce   => sub { path( $_[0] ) },
    trigger  => sub {
        my ( $self, $dir ) = @_;
        $self->_make_homedir($dir);
    },
);

has 'data_directory' => (
    is  => 'lazy',
    isa => sub {
        unless ( blessed( $_[0] ) && $_[0]->isa('Path::Tiny') ) {

            # $TRANSIENT_DB can be coerced to a Path::Tiny,
            # so this check still works.
            die "data_directory must be a valid path or Path::Tiny object\n";
        }
    },
    coerce => sub { path( $_[0] ) },
);

has 'dbh' => ( is => 'lazy', );

has 'author_photo_directory' => (
    is  => 'lazy',
    isa => sub {
        unless ( blessed( $_[0] ) && $_[0]->isa('Path::Tiny') ) {
            die "author_photo_directory must be a valid path or "
                . "Path::Tiny object\n";
        }
    },
    coerce => sub { path( $_[0] ) },
);

has 'ua' => (
    is      => 'ro',
    default => sub { LWP::UserAgent->new },
);

use Readonly;
Readonly my $IMAGEDIR_NAME => 'images';

no warnings "experimental::signatures";
use feature "signatures";

sub unblock_sources ( $self, @sources ) {
    my @failures;
    for my $source (@sources) {
        my ($extant) = $self->dbh->selectrow_array(
            'select * from block where source = ?',
            {}, $source );

        if ($extant) {
            $self->dbh->do( 'delete from block where source = ?',
                {}, $source );
        }
        else {
            push @failures, $source;
        }
    }
    return @failures;
}

sub block_sources ( $self, @sources ) {
    for my $source (@sources) {
        $self->dbh->do( 'insert into block values (?)', {}, $source );
    }
}

sub blocked_sources( $self ) {
    my @sources;
    my $sth = $self->dbh->prepare('select source from block order by source');
    $sth->execute;
    while ( my ($source) = $sth->fetchrow_array ) {
        push @sources, $source;
    }
    return @sources;
}

sub fetch_webmentions ( $self, $args ) {

    # This complex query lets us flexibly use the contents of the `block`
    # table as a blocklist.
    my $query =
          'select wm.* from wm where original_source not in '
        . '(select original_source from wm '
        . 'inner join (select source from block) b on '
        . ' wm.original_source like \'%\' || b.source || \'%\') ';
    my @wheres;
    my @bind_args;

    if ( $args->{before} ) {
        push @wheres,    "time_received <= ?";
        push @bind_args, $args->{before};
    }
    if ( $args->{after} ) {
        push @wheres,    "time_received >= ?";
        push @bind_args, $args->{after};
    }
    if ( $args->{source} ) {
        foreach ( $args->{source}->@* ) {
            push @wheres,    "original_source like ?";
            push @bind_args, "\%$_\%";
        }
    }
    if ( $args->{'not-source'} ) {
        foreach ( $args->{'not-source'}->@* ) {
            push @wheres,    "original_source not like ?";
            push @bind_args, "\%$_\%";
        }
    }
    if ( $args->{target} ) {
        push @wheres,    "target like ?";
        push @bind_args, "\%$args->{target}\%";
    }
    if ( $args->{type} ) {
        push @wheres,    "type like ?";
        push @bind_args, $args->{type};
    }

    # Unless we're processing WMs, we want only verified ones.
    if ( $args->{process} ) {
        push @wheres, "is_tested != 1";
    }
    else {
        push @wheres, "is_verified = 1";
    }

    my $where_clause = '';
    if (@wheres) {
        $where_clause = 'and ' . join( ' and ', @wheres );
    }

    $query .= "$where_clause order by time_received";

    my $sth = $self->dbh->prepare($query);
    $sth->execute(@bind_args);

    my @wms;
    while ( my $row = $sth->fetchrow_hashref ) {
        my %args = (
            source          => URI->new( $row->{source} ),
            target          => URI->new( $row->{target} ),
            original_source => $row->{original_source}
            ? URI->new( $row->{original_source} )
            : undef,
            title         => $row->{title},
            content       => $row->{content},
            source_html   => $row->{html},
            is_verified   => $row->{is_verified},
            is_tested     => $row->{is_tested},
            type          => $row->{type},
            time_received => DateTime::Format::ISO8601->parse_datetime(
                $row->{time_received}
            ),
            author_photo_hash => $row->{author_photo_hash},
            time_verified     => $row->{time_verified}
            ? DateTime::Format::ISO8601->parse_datetime(
                $row->{time_verified}
                )
            : undef,
        );

        # Delete keys that, if undef, we want the webmention object to
        # lazily re-derive
        foreach (
            qw(time_verified is_verified original_source content title type))
        {
            delete $args{$_} unless defined $args{$_};
        }

        if ( $row->{author_name} ) {
            my %author_args;
            $author_args{name} = $row->{author_name};
            foreach (qw(url photo)) {
                if ( $row->{"author_$_"} ) {
                    $author_args{$_} = $row->{"author_$_"};
                }
            }

            $args{author} = Web::Mention::Author->new( \%author_args );
        }
        my $wm = Whim::Mention->new( \%args );
        push @wms, $wm;

    }

    return @wms;

}

# process_webmentions: Verify all untested WMs.
sub process_webmentions( $self ) {
    my $verified_count = 0;
    my $total_count    = 0;
    my $sth            = $self->dbh->prepare(
              'update wm set is_tested = 1, is_verified = ?, '
            . 'author_name = ?, author_url = ?, author_photo = ?, '
            . 'time_verified = ?, html = ?, author_photo_hash = ?, '
            . 'type = ?, original_source = ?, content = ?, title = ? '
            . 'where source = ? and target = ? and time_received = ?' );

    for my $stored_wm ( $self->fetch_webmentions( { process => 1 } ) ) {
        $total_count++;

        # Verify a new, minimal wm based on the stored one.
        # This allows us to update re-sent wms that might have new content
        # (or might be deleted, or otherwise no longer valid).
        my $wm = Whim::Mention->new(
            {   source => $stored_wm->source,
                target => $stored_wm->target,
            }
        );

        # Grab the author image
        if ( $wm->author && $wm->author->photo ) {
            my $url      = $wm->author->photo->abs( $wm->source )->as_string;
            my $response = $self->ua->get($url);
            my $photo_hash = $self->_process_author_photo_tx($response);
            $wm->author_photo_hash($photo_hash);
        }

        my @bind_values = (
            $wm->author      ? $wm->author->name           : undef,
            $wm->author      ? $wm->author->url            : undef,
            $wm->author      ? $wm->author->photo          : undef,
            $wm->is_verified ? $wm->time_verified->iso8601 : undef,
            $wm->source_html,
            $wm->author_photo_hash,
            $wm->type,
            $wm->original_source->as_string,
            $wm->source_html ? $wm->content : undef,
            $wm->source_html ? $wm->title   : undef,
            $wm->source->as_string,
            $wm->target->as_string,
            $wm->time_received->iso8601,
        );

        if ( $wm->is_verified ) {
            $verified_count++;
            $sth->execute( 1, @bind_values );
        }
        else {
            $sth->execute( 0, @bind_values );
        }
    }
    return [ $verified_count, $total_count ];
}

sub receive_webmention ( $self, $wm ) {

    # If a wm with this source+target already exists in the db, then set it
    # to be re-verified, but don't modify its present verification state.
    # Otherwise, store a new wm, unverified and untested.
    my ($existing_wm) = $self->fetch_webmentions(
        {   source => [ $wm->source->as_string ],
            target => $wm->target->as_string,
        }
    );
    if ($existing_wm) {
        $self->dbh->do(
            'update wm set is_tested = 0 where source = ? and target = ?',
            {},
            $wm->source->as_string,
            $wm->target->as_string,
        );
    }
    else {
        $self->dbh->do(
            'insert into wm '
                . '(source, target, time_received, is_tested ) '
                . 'values (?, ?, ?, ? )',
            {},
            $wm->source->as_string,
            $wm->target->as_string,
            $wm->time_received->iso8601,
            0,
        );
    }
}

sub _build_dbh( $self ) {
    my $dir                     = $self->data_directory;
    my $db_needs_initialization = 1;
    my $db_file;

    if ( $dir eq $TRANSIENT_DB ) {
        $db_file = $dir;
    }
    else {
        $db_file                 = $dir->child('wm.db');
        $db_needs_initialization = 0 if $db_file->exists;
    }

    my $dbh =
        DBI->connect( "dbi:SQLite:$db_file", "", "", { sqlite_unicode => 1, },
        ) or die "Can't create or use a database file in $dir: $DBI::errtr\n";

    _initialize_database($dbh) if $db_needs_initialization;

    return $dbh;
}

sub _build_data_directory( $self ) {
    return $self->home->child('data');
}

sub _build_author_photo_directory( $self ) {
    return $self->home->child('public')->child('author_photos');
}

sub _process_author_photo_tx ( $self, $response ) {
    if ( $response->is_success ) {
        my $photo_hash = sha256_hex( $response->decoded_content );
        my $photo_file = $self->author_photo_directory->child($photo_hash);
        unless ( -e $photo_file ) {
            $photo_file->spew( $response->decoded_content );
        }
        return $photo_hash;
    }
    else {
        return undef;
    }
}

sub _initialize_database( $dbh ) {
    my @statements = (
        "CREATE TABLE wm (source char(128), original_source char(128), target "
            . "char(128), time_received text, is_verified int, is_tested int, "
            . "html text, content text, time_verified text, type char(16), "
            . "author_name char(64), author_url char(128), author_photo "
            . "char(128), author_photo_hash char(128), title char(255))",
        "CREATE UNIQUE INDEX source_target on wm(source, target)",
        "CREATE TABLE block (source char(128))",
        "CREATE UNIQUE INDEX source on block(source)",
    );

    foreach (@statements) {
        $dbh->do($_);
    }
}

sub _make_homedir ( $self, $dir ) {

    # Path::Tiny's mkpath() method executes without complaint if the path
    # already exists, so let's just create-if-needed every expected subdir.
    $dir->mkpath;
    $dir->child('log')->mkpath;
    $self->data_directory->mkpath;
    $self->author_photo_directory->mkpath;
}

1;

=head1 NAME

Whim::Core - A code library used by the Whim webmention multitool

=head1 DESCRIPTION

This is a code library used by the C<whim> executable. It doesn't have a
public interface!

=head1 SEE ALSO

L<whim>

=head1 AUTHOR

Jason McIntosh E<lt>jmac@jmac.orgE<gt>

