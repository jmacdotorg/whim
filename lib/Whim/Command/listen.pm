package Whim::Command::listen;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Server::Hypnotoad;
use Mojo::Util qw(getopt);

has description => 'bleep';
has usage       => sub { shift->extract_usage };

use Getopt::Long qw(GetOptionsFromArray);
my %options;

sub run {
    my ( $self, @args ) = @_;

    GetOptionsFromArray( \@args, \%options, qw(foreground help stop test) );

    # The WHIM_HYPNOTOAD environment variable tells the `whim`
    # executable that it's being run in "Hypnotoad context", adjusting
    # its default behavior.
    #
    # It also tells *this* command, that we shouldn't mess with
    # Hypnotoad's own environment variables any further.

    unless ( $ENV{WHIM_HYPNOTOAD} ) {
        foreach (qw(foreground stop test)) {
            $ENV{ 'HYPNOTOAD_' . uc($_) } = $options{$_};
        }

        # XXX Nothing for "help" right yet, alas!
    }

    $ENV{WHIM_HYPNOTOAD} = 1;

    my $toad = Mojo::Server::Hypnotoad->new;

    # XXX Someday, when we have app configuration, we will pass it into
    #     the $toad server object right around here.

    $toad->run( $self->app->home->child('script')->child('whim') );
}

1;
