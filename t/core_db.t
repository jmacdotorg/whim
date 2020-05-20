use warnings;
use strict;
use v5.20;

use Path::Tiny;
use Test::More tests => 3;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";
use Whim::Core;

subtest "Normal Whim::Core data initialization" => sub {
    plan tests => 2;

    # See DBD::SQLite: Using tempdir may confuse macOS file locks
    my $db_dir = Path::Tiny->tempdir( EXLOCK => 0 );

    my $whim = new_ok
        "Whim::Core" => [ { data_directory => $db_dir } ],
        "succeeds if data_directory exists";

    isa_ok $whim->dbh(), "DBI::db", "whim database handle";

};

subtest "Invalid Whim::Core data initialization" => sub {
    plan tests => 1;

    throws_ok sub { Whim::Core->new( { data_directory => undef } ) },
        qr/data_directory/,
        "dies if data_directory cannot be coerced to a Path::Tiny";
};

done_testing();
