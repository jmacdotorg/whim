package Whim::Command::listen;
use Mojo::Base 'Mojolicious::Command';

has description =>
    'Listen for incoming webmentions (and other HTTP requests)';
has usage => sub { shift->extract_usage };

use Mojo::Util qw(getopt);

use Daemon::Control;

use Mojo::Server::Prefork;
my %options;

sub run {
    my ( $self, @args ) = @_;

    my $command = $ARGV[-1];
    my $method  = "do_$command";

    unless ( Daemon::Control->can($method) ) {
        die $self->usage . "\n";
    }

    my $listener = $self->create_listener(@args);

    exit Daemon::Control->new(
        name         => "Whim listener",
        program      => \&launch_listener,
        program_args => [$listener],
        pid_file     => $listener->pid_file,
        fork         => 1,
    )->$method;
}

sub launch_listener {
    my ( $daemon_control, $listener ) = @_;
    $listener->daemonize;
    $listener->cleanup(1)->run;
}

sub create_listener {
    my ( $self, @args ) = @_;

    # This code is adapted from the Mojolicious::Command::prefork source.
    my $listener = Mojo::Server::Prefork->new( app => $self->app );
    getopt \@args,
        'a|accepts=i' => sub { $listener->accepts( $_[1] ) },
        'b|backlog=i' => sub { $listener->backlog( $_[1] ) },
        'c|clients=i' => sub { $listener->max_clients( $_[1] ) },
        'G|graceful-timeout=i' =>
        sub { $listener->graceful_timeout( $_[1] ) },
        'I|heartbeat-interval=i' =>
        sub { $listener->heartbeat_interval( $_[1] ) },
        'H|heartbeat-timeout=i' =>
        sub { $listener->heartbeat_timeout( $_[1] ) },
        'i|inactivity-timeout=i' =>
        sub { $listener->inactivity_timeout( $_[1] ) },
        'k|keep-alive-timeout=i' =>
        sub { $listener->keep_alive_timeout( $_[1] ) },
        'l|location=s' => \my @listen,
        'P|pid-file=s' => sub { $listener->pid_file( $_[1] ) },
        'p|proxy'      => sub { $listener->reverse_proxy(1) },
        'r|requests=i' => sub { $listener->max_requests( $_[1] ) },
        's|spare=i'    => sub { $listener->spare( $_[1] ) },
        'w|workers=i'  => sub { $listener->workers( $_[1] ) };

    $listener->listen( \@listen ) if @listen;

    return $listener;
}

1;

=encoding utf8

=head1 NAME

Whim::Command::listen - Listen command

=head1 SYNOPSIS

  Usage: whim listen [OPTIONS] [stop | start | restart | status]

  Examples:
    whim listen start
    whim listen -l http://*:8080 start
    whim listen -l 'https://*:443?cert=./server.crt&key=./server.key' start
    whim listen stop

  Options:
    -l, --location <location>            One or more locations you want to
                                         listen on, defaults to the value of
                                         MOJO_LISTEN or "http://*:3000"
    -P, --pid-file <path>                Path to process id file, defaults to
                                         "prefork.pid" in a temporary directory
    -p, --proxy                          Activate reverse proxy support,
                                         defaults to the value of
                                         MOJO_REVERSE_PROXY
    -w, --workers <number>               Number of workers, defaults to 4

  Logs to the "log" directory of Whim's home directory (usually $HOME/.whim).

  Additionaly, this program accepts all options supported by the Mojolicious
  prefork server. Try `mojo help prefork` to see the full list.

=head1 DESCRIPTION

Whim's daemon. It's basically just a L<Daemon::Control> instance wrapped
around a stock L<Mojo::Server::Prefork>.

=head1 SEE ALSO

L<whim>

=cut
