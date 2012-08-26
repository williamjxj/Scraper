#!/usr/bin/perl

my $stripname = `basename __FILE__ .pl`;

print `basename abc.pl .pl` . "\n";
print $stripname."\n";
$stripname = '_log_' unless $stripname;

print $stripname."\n";


