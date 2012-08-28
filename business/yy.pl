#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;

use lib qw(../lib/);
use google_config;
use db;
use google;

local ($|) = 1;
undef $/;

our $mech = undef;
our $g = undef;

$g = new google( '' );

my ($page_url, $paref) = ('', []);

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout(30);

my $url = 'http://ca.yahoo.com/?p=us&r691=1280946445';

$mech->get( $url );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'sf1',
    fields    => { p => 'martial arts studio' }
);
$mech->success or die $mech->response->status_line;

# print $mech->content;

$paref = $g->parse_yahoo_page( $g->strip_yahoo( $mech->content ));
$page_url = $paref->[1];

$mech->follow_link( url => $page_url );
$mech->success or die $mech->response->status_line;
# print $mech->content;

$paref = $g->parse_yahoo_page( $g->strip_yahoo( $mech->content ));
$page_url = $paref->[1];
# print Dumper($paref);
print $mech->content;

exit;

print "===========================================\n";

$paref = $g->parse_next_page( $mech->content );
$page_url = $paref->[1];

print $page_url . "\n";
print $mech->uri . "\n";
print Dumper($paref);
print "===========================================\n";

$mech->follow_link( url => $page_url );
$mech->success or die $mech->response->status_line;

$paref = $g->parse_next_page( $mech->content );
$page_url = $paref->[1];

print $page_url . "\n";
print $mech->uri . "\n";
print Dumper($paref);
exit;

