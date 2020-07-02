package Whim::Controller::Display;
use Mojo::Base 'Mojolicious::Controller';
use Whim::Mention;

use Readonly;
Readonly my $OK          => 200;
Readonly my $ACCEPTED    => 202;
Readonly my $BAD_REQUEST => 400;

sub display {
    my $self = shift;

    my $url = $self->param('url');

    unless ($url) {
        $self->render(
            status => $BAD_REQUEST,
            text   => 'No "url" parameter found.',
        );
        return;
    }

    # Grab all webmentions, then sort them into a hash-of-lists, keyed on type.
    my @webmentions = $self->whim->fetch_webmentions( { target => $url } );

    my %webmentions;
    for my $wm (@webmentions) {
        $webmentions{ $wm->type } //= [];
        push $webmentions{ $wm->type }->@*, $wm;
    }

    $self->stash->{webmentions}      = \%webmentions;
    $self->stash->{webmention_count} = scalar @webmentions;

    # Use the template 'webmentions', unless a 't' value is provided, in which
    # case use that (after a simple taint check)
    my $template_name = $self->param('t') // 'webmentions';
    if ( $template_name =~ /[^\-\w\d]/ ) {
        $self->render(
            status => $BAD_REQUEST,
            text   => 'Invalid template name.',
        );
        return;
    }

    $self->render($template_name);
}

1;
