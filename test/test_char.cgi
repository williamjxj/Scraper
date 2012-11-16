#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use CGI qw/:standard/;
use URI::Escape;

print header(-charset=>'utf-8');

my $str = "中国";
print length($str) . "\n";

Encode::_utf8_on($str);
print length($str) . "\n";

Encode::_utf8_off($str);
print length($str) . "\n";


