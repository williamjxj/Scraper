#!/usr/bin/perl

use strict;
use warnings;
use Encode;
use CGI qw/:standard/;
use URI::Escape;

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
my $utf8_str = uri_escape("收");
print uri_unescape($str);
print "<br>\n";

# 从中文得到perl unicode
utf8::decode($str);
my @chars = split //, $str;
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

=comment
E694B6
CAD5
%E6%94%B6
收
6536
\u6c49\u8bed
收
停车
=cut

$str='&#38463;&#26031;';  
$str=~s/&#(\d+);/chr(($1 + 0 ))/eg;
#$str=~s/&#(\d+);/pack('U' ,$ 1 )/eg;
#print(encode('gbk' ,$str));
print(encode('utf8' ,$str));
print "<br>\n";
