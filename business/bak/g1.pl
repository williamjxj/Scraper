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

# my $url = 'http://groups.google.com/groups/dir?sel=topic%3D46358.46348%2Ctopic%3D46358.46351&hl=en&';
# my $url = 'http://groups.google.com/groups/dir?sel=topic%3D46358.46348%2Ctopic%3D46358.46351%2C&start=15&hl=en&';
# my $url = 'http://groups.google.com/groups/dir?sel=topic%3D46358.46348%2Ctopic%3D46358.46351%2C&start=45&hl=en&';
#my $url = 'http://google.com';
my $url = 'http://www.google.ca';

$mech->get( $url );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'f',
    fields    => { q => 'martial arts studio', num => 100 }
);
$mech->success or die $mech->response->status_line;


$paref = $g->parse_next_page( $mech->content );
$page_url = $paref->[1];

##############
$page_url =~ s/\&amp;/&/g;
$page_url =~ s/ie=UTF-8\&//;
if ($page_url =~ m/start=/) {
	$page_url =~ s/start=\d+/start=200/;
}
else {
	$page_url .= '&start=300';
}
##############

$page_url = "http://www.google.com/#q=martial+arts+studio&hl=en&prmd=nm&ei=VrVYTKvbK4zUtQOLybnuCg&start=200&sa=N&fp=e0508b8cdb2068fd";
print $page_url . "\n";
print $mech->uri . "\n";
print Dumper($paref);

$mech->follow_link( url => $page_url );
$mech->success or die $mech->response->status_line;
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

