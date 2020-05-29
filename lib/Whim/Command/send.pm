package Whim::Command::send;
use Mojo::Base 'Mojolicious::Command';

use feature 'signatures';
no warnings qw(experimental::signatures);

use Whim::Mention;
use Try::Tiny;

has description => 'Send webmentions';
has usage       => "XXX Fill me in! XXX";

sub run {
    my ( $self, $source, $target ) = @_;

    $source = check_argument( source => $source );

    $target = check_argument( target => $target ) if defined $target;

    if ( defined $target ) {
        return $self->_send_one_wm( $source, $target );
    }
    else {
        return $self->_send_many_wms($source);
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

sub _send_many_wms ( $self, $source ) {

    my @wms;
    try {
        @wms = Whim::Mention->new_from_source($source);
    }
    catch {
        if (/lacks/) {
            chomp;
            say "Can't determine the content of the source document, so "
                . "declining to send any webmentions. ($_)";
        }
        return;
    };

    my $success_count = 0;
    for my $wm (@wms) {
        if ( $wm->send ) {
            $success_count++;
        }
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
