#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use CGI qw/:standard/;

print header(-charset=>'utf-8');

my $str = '%u6536';
$str =~ s/\%u([0-9a-fA-F]{4})/pack("U",hex($1))/eg;
$str = encode( "utf8", $str );

print $str;

