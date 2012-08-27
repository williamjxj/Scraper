#!/usr/bin/perl

use strict;
use warnings;
use Data::Dumper;

open FILE, "< ./logs/again.txt" or die $!;


my (@ary, $id, $url);

while (<FILE>) {
	chomp;
	print '['.$_."]\n";
	($id, $url) = ($_ =~ m /(.*),(.*)/);
	push(@ary, [$id, $url]);
}

close(FILE);

print Dumper(\@ary);

foreach my $r (@ary) {
	print $r->[0];
	print $r->[1];
}

