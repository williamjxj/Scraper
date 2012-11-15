#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use CGI qw/:standard/;

print header(-charset=>'utf-8');

#从unicode得到utf8编码
my $str = '%u6536';
$str =~ s/\%u([0-9a-fA-F]{4})/pack("U",hex($1))/eg;
$str = encode( "utf8", $str );
print uc unpack( "H*", $str );
print "<br>\n";

# 从unicode得到gb2312编码
$str = '%u6536';
$str =~ s/\%u([0-9a-fA-F]{4})/pack("U",hex($1))/eg;
$str = encode( "gb2312", $str );
print uc unpack( "H*", $str );
print "<br>\n";

# 从中文得到utf8编码
$str = "收";
print uri_escape($str);
print "<br>\n";

# 从utf8编码得到中文
$utf8_str = uri_escape("收");
print uri_unescape($str);
print "<br>\n";

# 从中文得到perl unicode
utf8::decode($str);
@chars = split //, $str;
foreach (@chars) {
    printf "%x ", ord($_);
}
print "<br>\n";

# 从中文得到标准unicode
my $a = "汉语";
$a = decode( "utf8", $a );
map { print "\\u", sprintf( "%x", $_ ) } unpack( "U*", $a );
print "<br>\n";

# 从标准unicode得到中文
$str = '%u6536';
$str =~ s/\%u([0-9a-fA-F]{4})/pack("U",hex($1))/eg;
$str = encode( "utf8", $str );
print $str;
print "<br>\n";

# 从perl unicode得到中文
my $unicode = "\x{505c}\x{8f66}";
print encode( "utf8", $unicode );
print "<br>\n";
