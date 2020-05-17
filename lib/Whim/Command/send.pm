package Whim::Command::send;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

use Web::Mention;

has description => 'Send webmentions';
has usage       => "XXX Fill me in! XXX";

sub run {
    my ($self, $source, $target) = @_;

    $source = check_argument( source => $source );

    $target = check_argument( target => $target );

    my $wm = Web::Mention->new( { source => $source, target => $target } );

    my $success = $wm->send;

    if ($success) {
        say "Webmention sent.";
    }
    else {
        say "No webmention sent.";
    }
}


sub check_argument ( $argument_name, $url_text ) {
    unless ( defined $url_text ) {
        die "Usage: $0 source-url target-url\n";
    }
    my $url = URI->new($url_text)
        or die
        "The argument for the $argument_name does not look like a valid "
        . "URL. (Got: $url_text)\n";

    return $url;
}

1;
