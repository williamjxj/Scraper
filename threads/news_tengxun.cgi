#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
use CGI qw/:standard/;
use Encode;
use LWP::Simple qw(!head);
use JSON;

binmode STDOUT, ":utf8";

my $url = q{http://news.soso.com/n.q?pid=n.home.result&ty=c&w=%CD%F5%B2%A8};
#my $url = q{http://news.soso.com/n.q?w=};
#my $url = q{http://news.soso.com/n.q?pid=n.search.active&ty=c&w=};
$url = q{http://news.soso.com/n.q?w=%CD%F5%B2%A8};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

#$keyword = encode("utf8", $keyword);

my $content = get $url;

my $html = strip_result( $content );

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 7;

###########################

sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <div\sid="result"
      .*?
      <ol.*?>
      (.*?) #soso用ol->li来划分每条记录
      </ol>
  }six;
  return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
  while ($html =~ m {
    <li
    .*?
    href="
    (.*?) #1.链接地址
    "
    (?:.*?)
    >
    (.*?) #2.标题
        </a>
        (?:.*?)
        </h3>
        (.*?) #3.正文
        </li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t3 =~ s/<div.*?<\/div>//gi;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
