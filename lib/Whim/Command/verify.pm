package Whim::Command::verify;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

has description => 'Verify webmentions';
has usage       => "XXX Fill me in! XXX";

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
