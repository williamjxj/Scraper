#!/usr/bin/perl -w
# Infrequently changing data
# Expensive to computeFrequently accessed
use strict;
use warnings;
use utf8;
#use encoding 'utf8';
use Cache::Memcached;
use Data::Dumper;
use Encode qw(decode encode);
use Cache::Memcached::Fast;

# Configure the memcached server.
my $cache = new Cache::Memcached {
	'servers' => [
		'localhost:11211',
	],
};

my $cmdline = join(' ', @ARGV);
#utf8::decode($cmdline);
#print $cmdline . "\n";

$cmdline = decode("utf-8", $cmdline);
my $include = $cache->get($cmdline);
print Dumper($include);

# auto increment $key by 1. Returns undef if $key doesn't exist, or new value after incrementing.

my $william = $cache->get("william");
#$cache->incr($william);
print Dumper($william);
#print $william->[0];

# my $hashref = $cache->get_multi(@keys);

my $memd = new Cache::Memcached::Fast({
	'servers' => [ 'localhost:11211', ],
});

my %val = $memd->get('william');
print Dumper(\%val);
