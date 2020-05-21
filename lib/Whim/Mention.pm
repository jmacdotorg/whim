package Whim::Mention;

use Moo;
extends 'Web::Mention';

has 'author_photo_hash' => (
    is  => 'rw',
    isa => sub {
        if ( defined $_[0] ) {
            die "Not a SHA256 hash" unless length $_[0] == 64;
        }
    },
);

1;
