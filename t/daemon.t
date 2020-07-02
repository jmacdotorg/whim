use Test::More;
use Test::Mojo;
use Whim::Core;
use FindBin;
use Mojo::File qw(path);

BEGIN {
    $ENV{WHIM_HOME} = $FindBin::Bin;
}

my $t = Test::Mojo->new('Whim');

# Initialize the app with test-specific config,
# and then make sure its default page is up.
set_up_app( $t->app );
$t->get_ok('/')->status_is(200)->content_like(qr/OK/);

# Send some wms to the listener:
# Create some Web::Mention objects, and then manually turn them into POST
# requests (instead of using the Web::Mention->send method).
my $wm_file = path("$FindBin::Bin/source/many_wms.html");

my @wms = Web::Mention->new_from_html(
    source => 'file://' . $wm_file->to_abs,
    html   => $wm_file->slurp,
);

for my $wm (@wms) {
    $t->post_ok(
        '/' => form => {
            source => $wm->source->as_string,
            target => $wm->target->as_string
        }
    )->status_is(202);
}

$t->app->whim->process_webmentions;

# See if we are displaying wms as expected:
# Just check one of the WMs we sent, a 'like', and see that it's displaying
# the sender's name in the resulting HTML.
$t->get_ok('/display_wms?url=http://example.com/like-target')->status_is(200)
    ->content_like(qr/Alice Nobody/);

# Check the default summary view too.
$t->get_ok('/summarize_wms?url=http://example.com/like-target')
    ->status_is(200)->content_like(qr/like.png/);

done_testing();

sub set_up_app {
    my ($t) = @_;

    # Reset the application home to the test directory
    $t->app->home( path($FindBin::Bin) );

    # Reset the template directory too
    $t->app->renderer->paths->[0] = $t->app->home->child('templates');

    # Swap out the app's Whim::Core object with our own test-friendly one
    my $whim = Whim::Core->new(
        {   data_directory => $Whim::Core::TRANSIENT_DB,
            home           => $FindBin::Bin,
        }
    );
    $t->app->helper( whim => sub {$whim} );

    # Erase any previously downloaded author photos.
    $t->app->home->child('public')->child('author_photos')
        ->list->each( sub { $_->remove } );
}
