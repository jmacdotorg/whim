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
        "Whim::Core" => [
        {   data_directory         => $db_dir,
            author_photo_directory => "$FindBin::Bin/public/author_photos",
        }
        ],
        "succeeds if data_directory exists";

    isa_ok $whim->dbh(), "DBI::db", "whim database handle";
};

subtest "Invalid Whim::Core data initialization" => sub {
    plan tests => 1;

    throws_ok sub {
        Whim::Core->new(
            {   data_directory => undef,
                author_photo_directory =>
                    "$FindBin::Bin/public/author_photos",
            }
        );
        },
        qr/data_directory/,
        "dies if data_directory cannot be coerced to a Path::Tiny";
};

subtest "Whim::Core in-memory database" => sub {
    plan tests => 4;

    ok my $transient_db = $Whim::Core::TRANSIENT_DB,
        '$Whim::Core::TRANSIENT_DB constant is defined';

    my $whim = new_ok
        "Whim::Core" => [
        {   data_directory         => $transient_db,
            author_photo_directory => "$FindBin::Bin/public/author_photos",
        }
        ],
        'succeeds if data_directory set to $Whim::Core::TRANSIENT_DB';

    my $expected_absence = "$transient_db/wm.db";
    ok( Path::Tiny->new($expected_absence)->assert( sub { !$_->exists } ),
        "Whim::Core didn't create a file for the in-memory database"
    );

    isa_ok $whim->dbh(), "DBI::db", "whim database handle";
};
done_testing();
