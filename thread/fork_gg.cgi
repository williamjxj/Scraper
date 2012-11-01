#!/usr/bin/perl

use strict;
use warnings;
use WWW::Mechanize;
use utf8;
use encoding 'utf8';
use CGI qw(:standard);
use JSON;
use Encode qw(decode);
use Data::Dumper;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use google;

use constant SURL => q{http://www.google.com};

#print "Content-type: text/html; charset=utf-8\n\n";
print header(-charset=>"UTF-8");

my $q = CGI->new;
my $keyword = $q->param('q');
#decode("utf-8", $keyword);

my $gg = new google();

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, ie=>'UTF-8', hl=>'zh-CN' }
);
$mech->success or die $mech->response->status_line;

my $t = $gg->strip_result( $mech->content );

my $aoh = $gg->parse_result($t);

#print Dumper($aoh);

my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh;

my $text = $json->encode($aoh);

print $text;

exit;

