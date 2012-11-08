#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use google;

#use constant SURL => q{http://www.google.com.hk};
use constant SURL => q{http://www.google.com};
#binmode(STDOUT, ":encoding(utf8)");

print header(-charset=>"UTF-8");

my $q = CGI->new;
my $keyword = $q->param('q');
# $keyword .= ' 负面新闻';
# Encode::decode("big5", $keyword);
Encode::_utf8_on($keyword);

my $gg = new google();

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
	form_name => 'f',
	fields    => {
		q => $keyword,
		ie=>'UTF-8',
		hl=>'zh-CN'
	}
);
$mech->success or die $mech->response->status_line;

=comment
my $html = $mech->content;
eval {my $str2 = $html; Encode::decode("gbk", $str2, 1)};
print "not gbk: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("utf8", $str2, 1)};
print "not utf8: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("big5", $str2, 1)};
print "not big5: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("gb2312", $str2, 1)};
print "not gb2312: $@\n" if $@;

# $gg->write_file('google1.html', $mech->content);
=cut

my $t = $gg->strip_result( $mech->content );

my $aoh = $gg->parse_result($t);

my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh;

my $text = $json->encode($aoh);

print $text;

exit;

