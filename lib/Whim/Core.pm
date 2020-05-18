package Whim::Core;

use warnings;
use strict;
use v5.24;

use Moo;
use DBI;
use Path::Tiny;
use Scalar::Util qw(blessed);
use DateTime::Format::ISO8601;
use Mojo::UserAgent;
use Digest::SHA qw(sha256_hex);

use lib '/Users/jmac/Documents/Plerd/indieweb/webmention-perl/lib';

use Web::Mention;

has 'data_directory' => (
    is  => 'ro',
    isa => sub {
        die "data_directory must be a valid path or Path::Tiny object\n"
            unless ( blessed( $_[0] ) && $_[0]->isa('Path::Tiny') );
    },
    required => 1,
    coerce   => sub { path( $_[0] ) },
);

has 'dbh' => ( is => 'lazy', );

has 'image_directory' => ( is => 'lazy', );

has 'ua' => (
    is      => 'ro',
    default => sub { Mojo::UserAgent->new },
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
            time_verified => $row->{time_verified}
            ? DateTime::Format::ISO8601->parse_datetime(
                $row->{time_verified}
                )
            : undef,
        );

        # Delete keys that, if undef, we want the webmention object to
        # lazily re-derive
        foreach (qw(time_verified is_verified original_source content title))
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
        else {
            $args{author} = undef;
        }
        my $wm = Web::Mention->new( \%args );
        push @wms, $wm;

    }

    return @wms;

}

# process_webmentions: Verify all untested WMs.
sub process_webmentions( $self ) {
    my $verified_count = 0;
    my $sth            = $self->dbh->prepare(
              'update wm set is_tested = 1, is_verified = ?, '
            . 'author_name = ?, author_url = ?, author_photo = ?, '
            . 'time_verified = ?, html = ?, author_photo_hash = ?, '
            . 'type = ?, original_source = ?, content = ?, title = ? '
            . 'where source = ? and target = ? and time_received = ?' );

    for my $wm ( $self->fetch_webmentions( { process => 1 } ) ) {

        # Grab the author image
        my $photo_hash;
        if ( $wm->author && $wm->author->photo ) {
            my $url = $wm->author->photo->as_string;
            $self->ua->get_p($url)->then(
                sub( $tx ) {    # Promise accepted
                    $photo_hash = $self->_process_author_photo_tx($tx);
                },
                sub( @args ) {    # Promise rejected
                    warn "Couldn't get author photo from $url: @args\n";
                }
            )->wait;
        }

        my @bind_values = (
            $wm->author      ? $wm->author->name           : undef,
            $wm->author      ? $wm->author->url            : undef,
            $wm->author      ? $wm->author->photo          : undef,
            $wm->is_verified ? $wm->time_verified->iso8601 : undef,
            $wm->source_html,
            $photo_hash,
            $wm->type,
            $wm->original_source->as_string,
            $wm->content,
            $wm->title,
            $wm->source->as_string,
            $wm->target->as_string,
            $wm->time_received->iso8601,
        );

        if ( $wm->is_verified ) {
            $verified_count++;
            $sth->execute( 1, @bind_values );
        }
        else {
            warn "FAILED to verify s:"
                . $wm->source->as_string . "t: "
                . $wm->target->as_string;
            $sth->execute( 0, @bind_values );
        }
    }
    return $verified_count;
}

# Receive_webmention: Treat the given wm as just-received, untested, unverified.
#                     Store its minimal info in the database. The expectation
#                     is that we'll process it later (see process_webmentions).
sub receive_webmention ( $self, $wm ) {
    $self->dbh->do(
        'insert into wm '
            . '(source, target, time_received, is_tested ) '
            . 'values (?, ?, ?, ? )',
        {},
        $wm->source->as_string,
        $wm->target->as_string,
        $wm->time_received->iso8601,
        0,
        0,
    );
}

sub _build_dbh( $self ) {
    my $dir = $self->data_directory;

    my $db_file                 = $dir->child('wm.db');
    my $db_file_already_existed = 1 if -e $db_file;

    my $dbh = DBI->connect( "dbi:SQLite:dbname=$dir/wm.db", "", "" );
    if ($dbh) {
        unless ($db_file_already_existed) {
            _initialize_database($dbh);
        }
        return $dbh;
    }
    else {
        die "Can't create or use a database file in $dir: $DBI::errtr\n";
    }
}

sub _build_image_directory( $self ) {
    return $self->data_directory->child($IMAGEDIR_NAME);
}

sub _process_author_photo_tx ( $self, $tx ) {
    my $photo_hash = sha256_hex( $tx->result->content->asset->slurp );
    my $photo_file = $self->image_directory->child($photo_hash);
    unless ( -e $photo_file ) {
        $tx->result->content->asset->move_to($photo_file);
    }
    return $photo_hash;
}

sub _initialize_database( $dbh ) {
    my @statements = (
        "CREATE TABLE wm (source char(128), original_source char(128), target char(128), time_received text, is_verified int, is_tested int, html text, content text, time_verified text, type char(16), author_name char(64), author_url char(128), author_photo char(128), author_photo_hash char(128), title char(255))",
        "CREATE TABLE block (source char(128))",
    );

    foreach (@statements) {
        $dbh->do($_);
    }
}

1;
