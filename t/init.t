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

my $t = Test::Mojo->new('Whim');

ok( $whim_home->child('data')->is_dir );
ok( $whim_home->child('public')->is_dir );
ok( $whim_home->child('public')->child('author_photos')->is_dir );
ok( $whim_home->child('log')->is_dir );

$whim_home->remove_tree;

done_testing();
