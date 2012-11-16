#!/usr/bin/perl -w
use strict;
use warnings;
use Data::Dumper;

my @time = localtime(time);
my $nowdate = sprintf( "%4d-%02d-%02d", $time[5] + 1900, $time[4] + 1,
$time[3] );
my $nowtime = sprintf( " %02d:%02d:%02d", $time[2], $time[1], $time[0] );
print $nowdate.$nowtime . "\n";

# In scalar context, localtime() returns the ctime(3) value:
my $now = localtime;

print '['.$now."]\n";

