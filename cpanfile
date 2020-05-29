requires "DBI";
requires "DBD::SQLite";
requires "DateTime::Format::ISO8601";
requires "Digest::SHA";
requires "FindBin";
requires "LWP::UserAgent";
requires "Mojolicious";
requires "Moo";
requires "MooX::ClassAttribute";
requires "Path::Tiny";
requires "Readonly";
requires "Scalar::Util";
requires "Test::Exception";
requires "Test::More";
requires "Try::Tiny";
requires "Web::Mention";
requires "feature";
requires "lib";
requires "strict";
requires "utf8::all";
requires "warnings";

on 'develop' => sub {
  requires 'Code::TidyAll';
  requires 'Perl::Tidy';
};
