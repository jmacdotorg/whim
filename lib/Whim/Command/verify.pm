package Whim::Command::verify;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

has description => 'Verify webmentions';
has usage       => sub { shift->extract_usage };

use Getopt::Long qw(GetOptionsFromArray);
my %options;
my $whim;

sub run {
    my ( $self, @args ) = @_;
    GetOptionsFromArray( \@args, \%options, 'quiet', );

    my $results_ref = $self->app->whim->process_webmentions;
    my ( $verified_count, $total_count ) = $results_ref->@*;
    if ($total_count) {
        my $s = $total_count == 1 ? '' : 's';
        speak(    "$verified_count of $total_count webmention${s} "
                . "passed verification." );
    }
    else {
        speak("No unverified webmentions to process.");
    }
}

sub speak {
    my ($utterance) = @_;
    say $utterance unless $options{quiet};
}

1;

=encoding utf8

=head1 NAME

Whim::Command::verify - Verify command

=head1 SYNOPSIS

  Usage: whim verify

=head1 DESCRIPTION

This command verifies webmentions, as described above. It prints a short
description of what it did to standard output.

It will automatically limit its work to those webmentions that have not already
had a verification attempt made on them.

=head1 SEE ALSO

L<whim>

=cut
