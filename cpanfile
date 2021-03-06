requires "DBI";
requires "DBD::SQLite";
requires "Daemon::Control";
requires "DateTime::Format::ISO8601";
requires "Digest::SHA";
requires "FindBin";
requires "LWP::Protocol::https";
requires "LWP::UserAgent";
requires "Mojolicious", ">= 8.25";
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
