package Whim::Command::query;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

has description => 'Fetch webmentions';
has usage       => "XXX Fill me in! XXX";

use Getopt::Long qw(GetOptionsFromArray);
my %options;
my $whim;

sub run {
    my ( $self, @args ) = @_;
    GetOptionsFromArray(
        \@args,    \%options,   'before=s', 'after=s',
        'on=s',    'source=s@', 'target=s', 'not-source=s@',
        'process', 'count',     'block',    'list',
        'unblock',
    );

    massage_options();

    $whim = $self->app->whim;

    if ( $options{unblock} ) {
        my @failures = $whim->unblock_sources( $options{unblock}->@* );

        my $unchanged_count = @failures;
        my $changed_count =
            scalar( $options{unblock}->@* ) - $unchanged_count;

        if ( $changed_count && !$unchanged_count ) {
            say "OK, block list updated.";
        }
        elsif ( $changed_count && $unchanged_count ) {
            say "$changed_count rows removed from block list. (The remaining "
                . "$unchanged_count were not in the list to begin with.)";
        }
        else {
            say "Block list unchanged; none of these sources were in it.";
        }
        exit;
    }
    elsif ( $options{list} ) {
        say "Current blocklist:";
        say "==================";

        while ( my ($source) = $whim->blocked_sources ) {
            say $source;
        }
        exit;
    }

    my @wms = get_wms();

    if ( $options{count} ) {
        say "Matching webmentions: " . scalar @wms;
    }
    elsif ( $options{process} ) {
        if (@wms) {
            say "Verifying " . scalar @wms . " webmentions...";
            my $verified_count = $whim->process_webmentions;
            my $s              = $verified_count == 1 ? '' : 's';
            say "\n$verified_count webmention${s} passed verification.";
        }
        else {
            say "No unverified webmentions to process.";
        }
    }
    else {
        display_wms(@wms);
    }

    if ( $options{block} ) {
        say "Are you sure you want to "
            . ( @wms ? "unpublish all these webmentions, and " : '' )
            . "block any future webmention whose source matches "
            . "'$options{source}'? (Y/N)";
        my $response = <STDIN>;
        if ( $response =~ /^[Yy]/ ) {
            $whim->block_sources( $options{sources} - @* );
            say "OK, block list updated.";
        }
        else {
            say "OK, block list unchanged.";
        }
    }

}

sub get_wms {
    my @wms = $whim->fetch_webmentions( \%options );
    return @wms;
}

sub display_wms( @wms ) {
    for my $wm (@wms) {
        say "Type:     " . $wm->type;
        say "Received: " . $wm->time_received;
        say "Author:   " . $wm->author->name if $wm->author;
        say "Source:   " . $wm->original_source;
        say "Target:   " . $wm->target;
        if ( $wm->type eq 'mention' or $wm->type eq 'reply' ) {
            say "Title:    " . $wm->title;
        }
        say "";
    }
    unless (@wms) {
        say "No matching webmentions.";
    }
}

sub massage_options {
    my %raw_date_numbers;
    foreach (qw(before after on)) {
        next unless $options{$_};
        unless ( $options{$_} =~ /^\d\d\d\d-\d\d-\d\d$/ ) {
            die "ERROR: Dates must be in YYYY-MM-DD format.\n";
        }
        $raw_date_numbers{$_} = $options{$_};
        $raw_date_numbers{$_} =~ s/-//g;
    }
    if ( $options{on} && ( $options{before} || $options{after} ) ) {
        die "ERROR: You can't query both 'on' and 'before' or 'after'.\n";
    }
    if (   ( $options{before} && $options{after} )
        && ( $raw_date_numbers{before} > $raw_date_numbers{after} ) )
    {
        die
            "ERROR: The 'before' date must be earlier than any 'after' date.\n";
    }

    if ( $options{on} ) {
        $options{before} = $options{on};
        $options{after}  = $options{on};
    }
    if ( $options{before} ) {
        $options{before} = "$options{before}T23:59:59";
    }
    if ( $options{after} ) {
        $options{after} = "$options{after}T00:00:00";
    }

    if ( $options{block} ) {
        unless ( $options{source} ) {
            die "ERROR: You must specify a source fragement (-s or --source) "
                . "to add to the blocklist.\n";
        }
        if ( grep { $_ eq $options{source} } $whim->blocked_sources ) {
            die "ERROR: We're already blocking '$options{source}`.\n";
        }
        if ( $options{unblock} ) {
            die "ERROR: You can't block and unblock at the same time.\n";
        }
    }

    if ( $options{unblock} ) {
        unless ( $options{source} ) {
            die "ERROR: You must specify a source fragement (-s or --source) "
                . "to modify the blocklist.\n";
        }
    }

    $options{not_source} = $options{'not-source'};

}

1;
