package Whim;
use Mojo::Base 'Mojolicious';

use Whim::Core;
use Try::Tiny;

our $VERSION = '2020.05.18.00';

sub startup {
    my $self = shift;

    push @{ $self->commands->namespaces }, 'Whim::Command';
    $self->helper(
        whim => sub {
            state $whim = Whim::Core->new(
                {   data_directory => $self->home->child('data'),
                    author_photo_directory =>
                        $self->home->child('public')->child('author_photos'),
                }
            );
        }
    );

    my $r = $self->routes;

    $r->get('/')->to('listen#default');
    $r->post('/')->to('listen#receive');

    $r->get('/display_wms')->to('display#display');

}

1;
