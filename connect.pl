#! /usr/bin/perl

use strict;
use warnings;
use DBI;

my %attrs = (AutoCommit => 1);
my $dsn = "DBI:mysql:host=localhost;database=dixi";
my $dbh = DBI->connect($dsn, "dixitruth", "dixi123456", \%attrs) or die "Can't connect to MySQL server\n";

print "Connected.\n";
$dbh->disconnect();
