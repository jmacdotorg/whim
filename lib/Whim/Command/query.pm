package Whim::Command::query;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

has description => 'Fetch and display webmentions, or update your block-list';
has usage       => sub { shift->extract_usage };

use Getopt::Long qw(GetOptionsFromArray);
my %options;
my $whim;

sub run {
    my ( $self, @args ) = @_;
    GetOptionsFromArray(
        \@args,  \%options,   'before=s', 'after=s',
        'on=s',  'source=s@', 'target=s', 'not-source=s@',
        'count', 'block',     'list',     'unblock',
    );

    $whim = $self->app->whim;

    massage_options();

    if ( $options{unblock} ) {
        my @failures = $whim->unblock_sources( $options{source}->@* );

        my $unchanged_count = @failures;
        my $changed_count = scalar( $options{source}->@* ) - $unchanged_count;

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

        for my $source ( $whim->blocked_sources ) {
            say $source;
        }
        exit;
    }

    my @wms = get_wms();

    if ( $options{count} ) {
        say "Matching webmentions: " . scalar @wms;
    }
    else {
        display_wms(@wms);
    }

    if ( $options{block} ) {
        my $block_string = join ' or ', $options{source}->@*;
        say "Are you sure you want to "
            . ( @wms ? "unpublish all these webmentions, and " : '' )
            . "block any future webmention whose source matches "
            . "$block_string? (Y/N)";
        my $response = <STDIN>;
        if ( $response =~ /^[Yy]/ ) {
            $whim->block_sources( $options{source}->@* );
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

=encoding utf8

=head1 NAME

Whim::Command::query - Query command

=head1 SYNOPSIS

  Usage: whim query [OPTIONS]

  The default action is to display a list of stored webmentions, optionally
  filtered by the provided options. You can run other actions by providing
  different options, as listed below.

  Options:
    Actions:
      --count    Return only a count of matching webmentions
      --list     Display the current blocklist
      --block    Add source strings (via --source) to the blocklist
      --unblock  Remove source strings (via --source) from the blocklist

    Filters:                    Limit affected webmentions to those...
      --before=2020-01-01          received before this date
      --after=2020-01-01           received after this date
      --on=2020-01-01              received on this date exactly
      --source=example.com/foo     whose source URL contains this string
      --not-source=example.com/bar whose source URL lacks this string
      --target=mysite.example/bar  whose target URL contains this string

=head1 DESCRIPTION

This command queries Whim's webmention database, either to display
summaries of webmentions that meet criteria specified as command-line
options, or to manage one's blocklist.

You can specify multiple C<--source> or C<--not-source> flags, as needed.

=head1 NOTES AND BUGS

The blocklist-management stuff should really have its own command.
(GitHub issue #32)

This should be able to output JSON representations of webmentions
(GitHub issue #8)

=head1 SEE ALSO

L<whim>

=cut
