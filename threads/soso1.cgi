#!/usr/bin/perl

use strict;
use warnings;
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

binmode(STDOUT, ":encoding(utf8)");

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use soso;

use constant SURL => q{http://www.soso.com};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');
#Encode::decode("gbk", $keyword);
Encode::_utf8_on($keyword);

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'flpage',
	fields    => { 
		w => $keyword,
		pid=> 's.idx',
		cid=> 's.idx.se'
	}
);
$mech->success or die $mech->response->status_line;

my $html = $mech->content;

my $ss = new soso();
my $t = $ss->strip_result( $html);

my $aoh = $ss->parse_result($t);

my $json = JSON->new->allow_nonref;

my $text = $json->encode($aoh);

print $text;

exit 6;
