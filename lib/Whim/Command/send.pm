package Whim::Command::send;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

use Whim::Mention;
use Try::Tiny;

use Mojo::Util qw(getopt);

has description => 'Send webmentions';
has usage       => sub { shift->extract_usage };

use open ':std', ':encoding(UTF-8)';

sub run {
    my ( $self, @args ) = @_;

    my $limit_to_content = 0;
    getopt( \@args, 'c|content' => sub { $limit_to_content = 1 }, );

    my ( $source, $target ) = @args;

    $source = check_argument( source => $source );

    $target = check_argument( target => $target ) if defined $target;

    if ( defined $target ) {
        return $self->_send_one_wm( $source, $target );
    }
    else {
        return $self->_send_many_wms( $source, $limit_to_content );
    }
}

sub _send_one_wm ( $self, $source, $target ) {

    my $wm = Whim::Mention->new( { source => $source, target => $target } );

    my $success = $wm->send;

    if ($success) {
        say "Webmention sent.";
    }
    else {
        say "No webmention sent.";
    }
}

sub _send_many_wms ( $self, $source, $limit_to_content ) {

    my @wms;
    try {
        @wms = Whim::Mention->new_from_source( $source,
            limit_to_content => $limit_to_content, );
    }
    catch {
        chomp;
        say "Cannot send any webmentions: $_";
    };

    my $success_count = 0;
    if (@wms) {
        say "Attempting to send webmentions to...";
    }
    for my $wm (@wms) {
        if ( $wm->send ) {
            print "\x{2705} ";    # check mark
            $success_count++;
        }
        else {
            print "\x{274C} ";    # cross mark
        }
        say $wm->target;
    }

    my $attempt_count = scalar(@wms);

    my $attempt_s = $attempt_count == 1 ? '' : 's';
    my $success_s = $success_count == 1 ? '' : 's';

    say "Sent $success_count webmention$success_s "
        . "(from $attempt_count attempt$attempt_s)";
}

sub check_argument ( $argument_name, $url_text ) {
    unless ( defined $url_text ) {
        die "Usage: $0 source-url [target-url]\n";
    }
    my $url = URI->new($url_text)
        or die
        "The argument for the $argument_name does not look like a valid "
        . "URL. (Got: $url_text)\n";

    return $url;
}

1;

=encoding utf8

=head1 NAME

Whim::Command::send - Send command

=head1 SYNOPSIS

  Usage: whim send [OPTIONS] [source-url] [target-url]

  Examples:
    whim send https://example.com/source https://example.com/target
    whim send https://example.com/source
    whim send --content https://example.com/source

  Options:
    -c, --content                        When run in one-argument mode,
                                         send webmentions only to targets
                                         within the page's first h-entry
                                         with a content property


  Run with two arguments to send a single webmention with the given
  source and target URLs.

  Run with one argument to send webmentions to every valid target found
  within the content found at the given source URL.

=head1 DESCRIPTION

This command sends webmentions, as described above. It prints a short
description of what it did to standard output.

If called with one argument, it will attempt to load the content from
the given source URL, and then try to send webmentions to all linked
URLs found within.

=head1 SEE ALSO

L<whim>

=cut
