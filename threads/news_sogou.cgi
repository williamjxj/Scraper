#!/usr/bin/perl

use strict;
use warnings;
use CGI qw/:standard/;
use Encode;
use LWP::Simple qw(!head);
use JSON;

#binmode(STDIN, ":encoding(utf8)");
binmode STDOUT, ":utf8";

my $url = q{http://news.sogou.com/news?p=42040301&mode=1&query=};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

#my $keyword = "中国";
#my $keyword = "%D6%D0%B9%FA";

$keyword = encode("gbk", $keyword);

my $content = get $url.$keyword;

#################
#my $fh = FileHandle->new( '../html/t1.html', "w" );
#binmode $fh, ':utf8';
#print $fh $content;
#$fh->autoflush(1);
#$fh->close();
#################

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
      (?:<table\sclass="hint"|id="footer")
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
