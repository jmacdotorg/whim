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

    warn "url: $url\n";

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
    $self->render('webmentions');
}

1;
