use warnings;
use strict;
use v5.20;

use Test::More;
use FindBin;
use Web::Mention;
use Path::Tiny;
use Try::Tiny;

use lib "$FindBin::Bin/../lib";

BEGIN {
    use_ok("Whim::Core");
}

initialize_tests();

diag("Create Whim object");
my $whim = Whim::Core->new(
    {   data_directory => $Whim::Core::TRANSIENT_DB,
        home           => "$FindBin::Bin",
    }
);

{
    my $count = $whim->fetch_webmentions( {} );

    is( $count, 0, 'Zero wms in db at the start of testing.' );
}

{
    diag("Receive and verify new webmentions");

    path("$FindBin::Bin/source/many_wms.html")
        ->copy("$FindBin::Bin/source/test_wms.html");

    receive_webmentions();
    my $count = $whim->process_webmentions;
    is( $count->[0], 7, "Processed expected number of stored webmentions." );

    $count = $whim->fetch_webmentions( {} );

    is( $count, 7, 'Received WMs are in the database.' );

    my ($wm) = $whim->fetch_webmentions(
        { target => 'http://example.com/another-reply-target' } );
    is( length $wm->author_photo_hash, 64, 'Author photo hash has a value.' );
}

{
    diag("Re-receive and re-verify existing webmentions");

    receive_webmentions();

    my $count = $whim->fetch_webmentions( {} );
    is( $count, 7, "Expected number of still-verified webmentions found" );

    # Swap out the file that generated the webmentions for another file with
    # one of the links missing. This could cause one of the wms to fail
    # verification.
    path("$FindBin::Bin/source/many_wms_minus_one.html")
        ->copy("$FindBin::Bin/source/test_wms.html");

    $count = $whim->process_webmentions;
    is( $count->[0], 6, "Processed expected number of stored webmentions." );

    $count = $whim->fetch_webmentions( {} );
    is( $count, 6,
        'A webmention failed re-verification and is marked as such' );
}

{
    diag("Webmention querying");
    my @wms = $whim->fetch_webmentions( { target => 'reply-target' } );
    is( scalar(@wms), 2, "Simple query worked as expected." );
}

done_testing();

sub initialize_tests {
    my $run_dir = path("$FindBin::Bin/run");

    if ( -e $run_dir ) {

        foreach my $child ( path("$FindBin::Bin/run")->children ) {
            unless ( $child->basename =~ /^\./ ) {
                try { $child->remove_tree };
            }
        }
    }
    else {
        mkdir $run_dir;
    }

    mkdir "$FindBin::Bin/run/images";
    unless ( -e "$FindBin::Bin/public/author_photos" ) {
        mkdir "$FindBin::Bin/public/author_photos";
    }

}

sub receive_webmentions {
    diag("Webmention receipt (no tests)");
    my $wm_file = path("$FindBin::Bin/source/test_wms.html");

    my @wms = Web::Mention->new_from_html(
        source => 'file://' . $wm_file->absolute,
        html   => $wm_file->slurp,
    );

    for my $wm (@wms) {
        $whim->receive_webmention($wm);
    }
}
