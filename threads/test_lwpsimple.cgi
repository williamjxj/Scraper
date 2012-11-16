#!/usr/bin/perl
# work fine.
# sogou用GBK.

use strict;
use warnings;
use utf8;
use LWP::Simple;
use Encode;

#my $url = q{http://news.sogou.com/news?p=42040301&mode=1&query=};
my $url = q{http://news.soso.com/n.q?pid=n.home.result&ty=c&w=%CD%F5%B2%A8};
#my $url = q{http://news.soso.com/};
#my $url = q{http://www.soso.com/};

#my $keyword = "%D6%D0%B9%FA";
my $keyword = '中国';
$keyword=encode("gbk", $keyword);

#my $doc = get $url.$keyword;
my $doc = get $url;

print $doc;
