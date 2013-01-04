#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Encode qw(decode);
use CGI qw(:standard);
use JSON;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use yahoo;
use constant SURL => q{http://tw.search.yahoo.com/};

my $q = CGI->new;
my $keyword = $q->param('q');
Encode::_utf8_on($keyword);

my $yh = new yahoo();

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

print header(-charset=>"UTF-8");

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_id => 'sf',
	fields    => { p => $keyword }
);
$mech->success or die $mech->response->status_line;

my $t = $yh->strip_result( $mech->content );

my $aoh = $yh->parse_result($t);

#my $json = JSON->new->allow_nonref;
#my $text = $json->encode($aoh);

my $text = encode_json $aoh;
print $text;

exit 9;
