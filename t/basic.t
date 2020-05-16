use warnings;
use strict;
use v5.20;

use Test::More;
use FindBin;
use Web::Mention;
use Path::Tiny;
use Try::Tiny;

use lib "$FindBin::Bin/../lib";
use_ok("Brisote");

initialize_tests();

diag("Create Brisote object");
my $brisote = Brisote->new( { data_directory => "$FindBin::Bin/run" } );

{
    my $count = $brisote->fetch_webmentions( {} );

    is( $count, 0, 'Zero wms in db at the start of testing.' );
}

{
    diag("Webmention receipt (no tests)");
    my $wm_file = path("$FindBin::Bin/source/many_wms.html");

    my @wms = Web::Mention->new_from_html(
        source => 'file://' . $wm_file->absolute,
        html   => $wm_file->slurp,
    );

    for my $wm (@wms) {
        $brisote->receive_webmention($wm);
    }
}

{
    diag("Webmention verification");
    my $count = $brisote->process_webmentions;
    is( $count, 7, "Processed expected number of stored webmentions." );

    $count = $brisote->fetch_webmentions( {} );

    is( $count, 7, 'Received WMs are in the database.' );
}

{
    diag("Webmention querying");
    my @wms = $brisote->fetch_webmentions( { target => 'reply-target' } );
    is( scalar(@wms), 2, "Simple query worked as expected." );
}

done_testing();

sub initialize_tests {
    foreach my $child ( path("$FindBin::Bin/run")->children ) {
        try { $child->remove_tree };
    }
}
