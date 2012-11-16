#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use LWP::Simple;
use Encode;

my $url = q{http://news.sogou.com/news?p=42040301&mode=1&query=};

#my $keyword = "%D6%D0%B9%FA";
my $keyword = '中国';
$keyword=encode("gbk", $keyword);

my $doc = get $url.$keyword;

print $doc;
