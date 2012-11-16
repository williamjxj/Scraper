#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use WWW::Mechanize;
use Encode;

use constant SURL => q{http://news.sogou.com/};

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

my $keyword = "中国";
#$keyword=encode("gbk", $keyword);

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
