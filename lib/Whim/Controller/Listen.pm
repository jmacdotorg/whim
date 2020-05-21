package Whim::Controller::Listen;
use Mojo::Base 'Mojolicious::Controller';
use Whim::Mention;

use Readonly;
Readonly my $OK          => 200;
Readonly my $ACCEPTED    => 202;
Readonly my $BAD_REQUEST => 400;

sub default {
    my $self = shift;

    $self->render(
        status => $OK,
        text   => 'OK (listening for webmentions)'
    );
}

sub receive {
    my $self = shift;

    my $webmention;
    try {
        $webmention = Whim::Mention->new_from_request($self);
    }
    catch {
        $self->render(
            status => $BAD_REQUEST,
            text   => "Malformed webmention: $_"
        );
        $self->log->info('Rejected a malformed webmention.');
    };
    return unless $webmention;

    # Pull out the source and target params, mostly for logging
    my $source = $self->param('source');
    my $target = $self->param('target');

    # XXX For the present, naively accept all webmentions.
    #     This is technically legal under section 3.2.1 of the spec.
    #     But it SHOULD check against some stored config about whether
    #     it cares about the target URL at all.
    unless (1) {
        my $error_text = "Unrecognized target URL: $target";
        $self->render(
            status => $BAD_REQUEST,
            text   => $error_text
        );
        $self->log->info($error_text);
        return;
    }

    my $success_text =
          "Webmention accepted, and queued for verification and "
        . "processing. Thank you!";

    my $return_link_text = 'Return to previous page.';
    $success_text .= qq{ <a href="$target">$return_link_text</a>};

    $self->render( status => $ACCEPTED, text => $success_text );

    $self->log->info("Accepted: $source -> $target");

    $self->whim->receive_webmention($webmention);
}

1;
