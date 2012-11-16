#!/usr/bin/perl
#很奇怪，www.baidu.com,www.soso.com都能和www::mechanize一起工作。
# news.163.com也是。
# 代码daemons/, threads/.cgi, threads/news都大同小异，都是decode('utf8',keyword)然后调用mechanize的submit_form()
# 但是，news.soso.com, news.sogou.com不可以。我花了两天多的时间，就是调不通，总是乱码。
# 无论gbk,gb2312/euc-cn, utf8/utf-8,还是
# encode,decode,from_to全都用上了，就是不行。开始怀疑是字符编码的转换，尝试了%CD%F5%B2%A8，’中国‘等多种方式，就是不行。
# 后来才怀疑是Mechanize的问题：
# I was recently (and graciously) informed here that later versions of www::mechanize will automatically encode pages 
# (in utf8 it would seem).
# 将 www::mechanize转化为LWP::Simple就可以了！
# javascript的UrlEncode,将’中国‘转换为%CD%F5%B2%A8，等于Perl的encode("gbk", '中国')

use strict;
use warnings;
use CGI qw/:standard/;
use Encode;
use LWP::Simple;
use JSON;

#binmode(STDIN, ":encoding(utf8)");
binmode STDOUT, ":utf8";

my $url = q{http://news.sogou.com/news?p=42040301&mode=1&query=};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

#my $keyword = "中国";
#my $keyword = "%D6%D0%B9%FA";

$keyword=encode("gbk", $keyword);

my $content = get $url.$keyword;

my $html = strip_result($content);

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 8;

###########################

sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <div\sclass="results"
	  .*?
	  >
      (.*?) #soso用ol->li来划分每条记录
      <table\sclass="hint"
  }six;
  return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
  while ($html =~ m {
    class="pt"
    .*?
    href="
    (.*?) #1.链接地址
    "
    (?:.*?)
    >
    (.*?) #2.标题
        </a>
        (?:.*?)
        <div\sclass="ft">
        (.*?) #3.正文
        </div>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t3 =~ s/<a.*?<\/a>//ig;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
