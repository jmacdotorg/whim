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

    is( scalar @wms, 7, "Extracted expected webmentions from source doc." );

    throws_ok(
        sub {
            my $wm_file = path("$FindBin::Bin/source/no_entry.html");
            my @wms     = Whim::Mention->new_from_source(
                'file://' . $wm_file->absolute,
                limit_to_entry => 1, );
        },
        qr/lacks an h-entry microformat/,
        "Correctly refused to extract wms from souce doc with no h-entry.",
    );
}

done_testing();
