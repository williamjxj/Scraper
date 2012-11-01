#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use CGI qw(:standard);
use JSON;
use Encode qw(from_to encode decode);
use Encode::CN;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use soso;

use constant SURL => q{http://www.soso.com};

#print "Content-type: text/html; charset=utf-8\n\n";
print header(-charset=>"UTF-8");

my $q = CGI->new;
my $keyword = $q->param('q');
#decode("utf-8", $keyword);
#$keyword = decode("euc-cn", "$keyword");

my $ss = new soso();

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'flpage',
	fields    => { w => $keyword }
);
$mech->success or die $mech->response->status_line;

my $t = $ss->strip_result( $mech->content );

my $aoh = $ss->parse_result($t);

# print Dumper($aoh);

my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh;
$aoh = ['soso.cgi', $keyword, $keyword];

my $text = $json->encode($aoh);

print $text;
exit 6;

