#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'gbk';
use WWW::Mechanize;
use Data::Dumper;
use CGI qw(:standard);
use JSON;
#use Encode qw(from_to encode decode);
use Encode;

#binmode(STDIN, ":encoding(utf8)");
#binmode(STDOUT, ":encoding(gbk)");

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use soso;

use constant SURL => q{http://www.soso.com};

#print "Content-type: text/html; charset=utf-8\n\n";

print header(-charset=>'gbk');
#print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');
#encode("utf-8", $keyword);
#$keyword = decode("euc-cn", "$keyword");
#Encode::encode("gbk", $keyword);

# $keyword = Encode::_utf8_on($keyword);

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

$ss->write_file('soso1.html', $mech->content);

#my $html = Encode::decode("gbk", $mech->content);
my $html = $mech->content;
#print Dumper($html);

exit;

=comment
eval {my $str2 = $html; Encode::decode("gbk", $str2, 1)};
print "not gbk: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("utf8", $str2, 1)};
print "not utf8: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("big5", $str2, 1)};
print "not big5: $@\n" if $@;

eval {my $str2 = $html; Encode::decode("gb2312", $str2, 1)};
print "not gb2312: $@\n" if $@;
=cut

my $t = $ss->strip_result( $html);

my $aoh = $ss->parse_result($t);

print Dumper($aoh);

exit;
my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh; #$aoh = ['soso.cgi', $keyword, $keyword];

my $text = $json->encode($aoh);

print $text;

exit 6;
