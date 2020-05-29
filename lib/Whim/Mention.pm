package Whim::Mention;

use Moo;
use MooX::ClassAttribute;
extends 'Web::Mention';

use Web::Microformats2::Parser;

has 'author_photo_hash' => (
    is  => 'rw',
    isa => sub {
        if ( defined $_[0] ) {
            die "Not a SHA256 hash" unless length $_[0] == 64;
        }
    },
);

class_has 'mf2_parser' => (
    is => 'ro',
    default => sub { Web::Microformats2::Parser->new },
);

sub new_from_source {
    my ( $class, $source ) = @_;

    my $response = $class->ua->get( $source );

    if ( $response->is_success ) {
        my $mf2_doc = $class->mf2_parser->parse( $response->content, ( url_context => $source ) );
        my $entry = $mf2_doc->get_first( 'entry' );
        my $content = $entry->get_property( 'content' ) if $entry;
        if ( $content ) {
            return $class->new_from_html( source => $source, html => $content->{html} );
        }
        else {
            die "Content at $source lacks an h-entry microformat with an e-content property.\n";
        }
    }
    else {
        die "Could not fetch content from $source: " . $response->status_line . "\n";
    }
}

1;
