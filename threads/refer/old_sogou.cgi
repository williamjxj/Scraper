#!/usr/bin/perl
# NOT WORK!

use strict;
use warnings;
use utf8;
#use encoding "gbk";
use WWW::Mechanize;
use CGI qw/:standard/;
use Encode;

use constant SURL => q{http://news.sogou.com/};

print header(-charset=>'gbk');
my $keyword = "中国";
# my $keyword = "%D6%D0%B9%FA";

#Encode::from_to($keyword, "utf8", "gbk");

$keyword=encode ("gbk",decode("utf-8",$keyword));

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'searchForm',
    fields    => {
    query => $keyword,
    p => '42040301',
    mode => 1
  }
);
$mech->success or die $mech->response->status_line;
#print $mech->content;

my $fh = FileHandle->new('../html/t6.html', "w" );
binmode $fh, ':utf8';
print $fh $mech->content;
$fh->autoflush(1);
$fh->close();

