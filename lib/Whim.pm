package Whim;
use Mojo::Base 'Mojolicious';

use Whim::Core;
use Try::Tiny;

use Readonly;
Readonly my $OK          => 200;
Readonly my $ACCEPTED    => 202;
Readonly my $BAD_REQUEST => 400;

sub startup {
    my $self = shift;

    push @{ $self->commands->namespaces }, 'Whim::Command';
    $self->helper(
        whim => sub {
            state $whim = Whim::Core->new(
                { data_directory => "$FindBin::Bin/../data" } );
        }
    );

    my $r = $self->routes;

    $r->post(
        '/' => sub {
            my $c = shift;

            my $webmention;
            try {
                $webmention = Web::Mention->new_from_request($c);
            }
            catch {
                $c->render(
                    status => $BAD_REQUEST,
                    text   => "Malformed webmention: $_"
                );
                $c->log->info('Rejected a malformed webmention.');
            };
            return unless $webmention;

            # Pull out the source and target params, mostly for logging
            my $source = $c->param('source');
            my $target = $c->param('target');

            # XXX For the present, naively accept all webmentions.
            #     This is technically legal under section 3.2.1 of the spec.
            #     But it SHOULD check against some stored config about whether
            #     it cares about the target URL at all.
            unless (1) {
                my $error_text = "Unrecognized target URL: $target";
                $c->render(
                    status => $BAD_REQUEST,
                    text   => $error_text
                );
                $c->log->info($error_text);
                return;
            }

            my $success_text =
                  "Webmention accepted, and queued for verification and "
                . "processing. Thank you!";

            my $return_link_text = 'Return to previous page.';
            $success_text .= qq{ <a href="$target">$return_link_text</a>};

            $c->render( status => $ACCEPTED, text => $success_text );

            $c->log->info("Accepted: $source -> $target");

            $c->whim->receive_webmention($webmention);
        }
    );

    $r->get(
        '/' => sub {
            my $c = shift;

            $c->render(
                status => $OK,
                text   => 'OK (listening for webmentions)'
            );
        }
    );

}

1;
