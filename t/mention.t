# Tests specific to Whim::Mention, absent the rest of Whim::Core.

use warnings;
use strict;
use v5.20;

use Test::More;
use Test::Exception;
use FindBin;

use lib "$FindBin::Bin/../lib";
use Whim::Mention;
use Path::Tiny;

{
    diag("Send lots of webmentions based on one page");

    my $wm_file = path("$FindBin::Bin/source/many_wms.html");
    my @wms =
        Whim::Mention->new_from_source( 'file://' . $wm_file->absolute, );

    is( scalar @wms, 6, "Extracted expected webmentions from source doc." );

    throws_ok(
        sub {
            my $wm_file = path("$FindBin::Bin/source/no_content.html");
            my @wms     = Whim::Mention->new_from_source(
                'file://' . $wm_file->absolute,
            );
        },
        qr/lacks an h-entry microformat with an e-content property/,
        "Correctly refused to extract wms from souce doc with no e-content.",
    );
}

done_testing();
