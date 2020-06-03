package Whim;
use Mojo::Base 'Mojolicious';

use Mojo::File qw(curfile);
use Whim::Core;

use Path::Tiny;

our $VERSION = '2020.05.18.00';

sub startup {
    my $self = shift;

    # Switch the app's home to ~/.whim/
    # (overridable by environment variable)
    $self->home(
        Mojo::Home->new(
            path( $ENV{WHIM_HOME} // $ENV{HOME} )->child('.whim')
        )
    );

    my $config =
        $self->plugin( 'Config', { default => { home => $self->home, }, } );

    push @{ $self->commands->namespaces }, 'Whim::Command';

    # Create a 'whim' helper containing our Whim::Core object
    $self->helper(
        whim => sub {
            state $whim = Whim::Core->new($config);
        }
    );

    # Set up docroot and template paths.
    # For both, the first place to look is the app home, and then using
    # the library directory as a fallback.
    $self->static->paths(
        [   $self->home->child('public'),
            curfile->sibling('Whim')->child('public'),
        ]
    );

    $self->renderer->paths(
        [   $self->home->child('templates'),
            curfile->sibling('Whim')->child('templates'),
        ]
    );

    # Set up routes for the listener
    my $r = $self->routes;

    $r->get('/')->to('listen#default');
    $r->post('/')->to('listen#receive');

    $r->get('/display_wms')->to('display#display');

}

1;

=head1 NAME

Whim - A code library used by the Whim webmention multitool

=head1 DESCRIPTION

This is a code library used by the C<whim> executable. It doesn't have a
public interface!

=head1 SEE ALSO

L<whim>

=head1 AUTHOR

Jason McIntosh E<lt>jmac@jmac.orgE<gt>
