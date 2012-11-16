#!/usr/bin/perl

use strict;
use warnings;
use CGI qw/:standard/;
use Encode;
use LWP::Simple qw(!head);
use JSON;

binmode STDOUT, ":utf8";

my $url = q{http://news.so.com/ns?src=srp&tn=news};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

Encode::_utf8_on($keyword);

$url .= '&q='.$keyword.'&pq='.$keyword;

my $content = get $url;

my $fh = FileHandle->new( '../html/t2.html', "w" );
binmode $fh, ':utf8';
print $fh $content;
$fh->autoflush(1);
$fh->close();

my $html = strip_result( $content );

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 9;

###########################
#
sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <ul\sid="results"
      .*?
      >
      (.*?) #soso用ol->li来划分每条记录
      </ul>
  }six;
  return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
  while ($html =~ m {
    <h3
    .*?
    href="
    (.*?) #1.链接地址
    "
    (?:.*?)
    >
    (.*?) #2.标题
        </a>
        (?:.*?)
        <p>
        (.*?) #3.正文
        </p>
        (?:.*?)
        </li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t3 =~ s/<nobr.*?<\/nobr>//gi;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
