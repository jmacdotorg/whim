use Test::More;
use Test::Mojo;
use FindBin;

use Path::Tiny;

# These tests check that Whim, given a manually set WHIM_HOME environment
# variable aiming at a non-existent directory, will set up a new home
# environment for itself there.

my $whim_home;

BEGIN {
    $whim_home = path( $FindBin::Bin, 'run', 'testhome' );
    $whim_home->remove_tree;    # Clean up from possible earlier failed test

    $ENV{WHIM_HOME} = "$whim_home";
}

# Test with no homedir at all
check_dirs();

# Test with a partially present homedir
$whim_home->mkpath;
check_dirs();

done_testing();

sub check_dirs {
    my $t = Test::Mojo->new('Whim');

    # Force the whim helper object to instantiate itself, just so it sets up
    # its home directory.
    $t->app->whim;

    ok( $whim_home->child('data')->is_dir );
    ok( $whim_home->child('public')->is_dir );
    ok( $whim_home->child('public')->child('author_photos')->is_dir );
    ok( $whim_home->child('log')->is_dir );

    # And then clean everything up again.
    $whim_home->remove_tree;
}

