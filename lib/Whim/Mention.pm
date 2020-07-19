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
    is      => 'ro',
    default => sub { Web::Microformats2::Parser->new },
);

sub new_from_source {
    my ( $class, $source, %options ) = @_;

    my $response = $class->ua->get($source);

    if ( $response->is_success ) {
        my $html;
        if ( $options{limit_to_content} ) {
            my $mf2_doc = $class->mf2_parser->parse( $response->content,
                ( url_context => $source ) );
            my $entry   = $mf2_doc->get_first('entry');
            my $content = $entry->get_property('content') if $entry;
            if ($content) {
                $html = $content->{html} // '';
            }
            else {
                die "Content at $source lacks an h-entry microformat "
                    . "with an e-content property.\n";
            }
        }
        else {
            $html = $response->content;
        }
        return $class->new_from_html(
            source => $source,
            html   => $html,
        );
    }
    else {
        die "Could not fetch content from $source: "
            . $response->status_line . "\n";
    }
}

1;

=head1 NAME

Whim::Mention - A code library used by the Whim webmention multitool

=head1 DESCRIPTION

This is a code library used by the C<whim> executable. It doesn't have a
public interface!

=head1 SEE ALSO

L<whim>

=head1 AUTHOR

Jason McIntosh E<lt>jmac@jmac.orgE<gt>

