#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'gbk';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

#binmode(STDIN, ":encoding(utf8)");
binmode(STDOUT, ":encoding(utf8)");

use constant SURL => q{http://news.sosgou.com};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');
Encode::_utf8_on($keyword);

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'searchForm',
    fields    => { query => $keyword }
);
$mech->success or die $mech->response->status_line;

#my $html = Encode::decode("gbk", $mech->content);
my $html = strip_result($mech->content);

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 8;

###########################

sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <div\sid="result"
      .*?
      <ol\sid="result_list">
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
        <span(?:.*?)>
        (.*?) #3.正文
        </span>
        (?:.*?)
        </li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
