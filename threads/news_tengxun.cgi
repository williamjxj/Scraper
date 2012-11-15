#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf-8';
#use encoding 'gb2312';
#use encoding "euc-cn";
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;
use URI::Escape;

binmode(STDOUT, ":utf8");

use constant SURL => q{http://news.soso.com/};

print header(-charset=>'utf-8');

my $q = CGI->new;

my $keyword = '王波';

#$keyword = Encode::encode('gb2312', $keyword);
#$keyword =~s/(\W)/sprintf("%%%02X",unpack("C",$1))/eg;

$keyword = uri_escape_utf8($keyword);
#print $keyword . "\n"; exit;

$keyword = '%CD%F5%B2%A8';
#Encode::_utf8_on($keyword);
#$keyword = Encode::encode('gb2312', $keyword);

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
  form_name => 'flpage',
  fields    => { 
    ty => 'c',
    pid=>'n.home.result',
    w => $keyword
  }
);
$mech->success or die $mech->response->status_line;

my $fh = FileHandle->new('../html/t3.html', "w" );
binmode($fh, ":utf8");
print $fh $mech->content;
$fh->autoflush(1);
$fh->close();

my $html = strip_result( $mech->content );

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
