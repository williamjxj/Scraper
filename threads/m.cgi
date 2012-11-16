#!/usr/bin/perl

use strict;
use warnings;
use encoding "gbk";
use WWW::Mechanize;
use CGI qw/:standard/;
use Encode;

binmode STDOUT, ":utf8";

use constant SURL => q{http://news.sogou.com/};

print header(-charset=>'gbk');

my $keyword = "中国";
# my $keyword = "%D6%D0%B9%FA";

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

print $mech->content;