package Whim::Command::listen;
use Mojo::Base 'Mojolicious::Command';

use Mojo::Server::Hypnotoad;

use FindBin;

has description =>
    'Listen for incoming webmentions (and other HTTP requests)';
has usage => sub { shift->extract_usage };

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

    $toad->run("$FindBin::Bin/whim");

}

1;

=encoding utf8

=head1 NAME

Whim::Command::listen - Listen command

=head1 SYNOPSIS

  Usage: whim listen [OPTIONS]

  Examples:
    whim listen
    whim listen --stop

  Options:
    --stop                  Stop the listener
    --foreground            Run the listener in the foreground

=head1 DESCRIPTION

This command just runs a L<hypnotoad> instance, configured to use your
local L<Whim> installation. It will respect any Hypnotoad-specific
environment variables and other configuration that you might have set.

Logs and pidfiles and such will go into C<$HOME/.whim/>.

This script is currently too stupid to listen to any location other than
http://*:8080. Hope that's what you want! (See L<"NOTES AND BUGS">.)

=head1 NOTES AND BUGS

This script is extremely preliminary, and actually rather rubbish. Every
part of it is subject to change.

=head1 SEE ALSO

L<whim>

=cut
