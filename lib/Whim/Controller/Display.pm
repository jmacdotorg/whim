package Whim::Controller::Display;
use Mojo::Base 'Mojolicious::Controller';
use Whim::Mention;
use List::Util qw/ pairmap /;

use Readonly;
Readonly my $BAD_REQUEST => 400;

sub serialize_wm {
    my $wm = shift;

    my $data = $wm->TO_JSON;

    # TO_JSON doesn't put all the yumminess
    # in the hash, so I augment with the
    # other stuff I want

    if( my $author = $wm->author ) {
        $data->{author} = {
            map { $_ => $author->$_ } qw/ name url photo /
        }
    }

    if( $wm->author_photo_hash ) {
        $data->{author}{local_photo} =
             '/author_photos/' . $wm->author_photo_hash;
    }

    return $data;
}

sub json {
    my $self = shift;

    return unless $self->_get_wms;

    my %mentions = pairmap {
        $a => [ map { serialize_wm($_) } @$b ]
    } %{ $self->stash->{webmentions} };

    $self->render( json => \%mentions );
}

sub display {
    my $self = shift;

    return unless $self->_get_wms;

    $self->render('webmentions');
}

sub summarize {
    my $self = shift;

    return unless $self->_get_wms;

    $self->render('summary');
}

sub _get_wms {
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

    # Initialize %webmentions with an empty list for each webmention type that
    # Web::Mention supports (plus one or two extras, perhaps)
    foreach (qw( mention reply like repost quotation rsvp bookmark )) {
        $webmentions{$_} = [];
    }

    for my $wm (@webmentions) {
        unless ( $webmentions{ $wm->type } ) {
            die "Unknown webmention type: " . $wm->type;
        }
        push $webmentions{ $wm->type }->@*, $wm;
    }

    $self->stash->{webmentions}      = \%webmentions;
    $self->stash->{webmention_count} = scalar @webmentions;

    return 1;
}

1;
