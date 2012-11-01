#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use CGI;
use JSON;
use Encode qw(decode);

BEGIN{
	if ( $^O eq 'MSWin32' ) {
		use lib qw(../lib/);
	}
	else {
		use lib qw(/home/williamjxj/scraper/lib/);
	}
}
use config;
use yahoo;

use constant SURL => q{http://search.yahoo.com/};

my $q = CGI->new;
my $keyword = $q->param('q');
decode("utf-8", $keyword);

my $cn = new yahoo();

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_id => 'sf',
	fields    => { p => $keyword }
);
$mech->success or die $mech->response->status_line;

$h->{'author'} = $cn->{'dbh'}->quote($mech->uri()->as_string) if($mech->uri);

my $t = $cn->strip_result( $mech->content );

my $aoh = $cn->parse_result($t);

print Dumper($aoh);

my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh;

my $text = $json->encode($aoh);

print $text;
exit 6;

