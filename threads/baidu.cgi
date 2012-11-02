#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf8';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Data::Dumper;
use Encode qw(from_to decode encode);

use lib qq{/home/williamjxj/scraper/lib/};
use config;
use common;

#binmode(STDIN, ":encoding(utf8)");
#binmode(STDOUT, ":encoding(utf8)");

use constant SURL => 'http://www.baidu.com';

print header(-charset=>"UTF-8"); #print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
=comment
foreach my $name ($q->param) {
	if (  $name =~ m/\_/ ) { next;
	} else {
		print "<p> [".$name."]\t=\t[".$q->param($name) . "]</p>\n";
	}
}
=cut

my $keyword = $q->param('q');
Encode::decode("gbk", $keyword);
Encode::_utf8_on($keyword);

our $bd = new common() or die $!;

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    'form_name' => 'f',
	'fields'    => {
		wd => $keyword,
		ie => 'utf-8',
		'rsv_bp' => 1,
		'bs' => $keyword
	}
);
$mech->success or die $mech->response->status_line;

# $bd->write_file('bd1.html',$mech->content); #display correctly.

my $t = strip_result( $mech->content );

my $aoh = parse_result($t);

my $json = JSON->new->allow_nonref;

my $text = $json->encode($aoh);

print $text;

exit 8;

########################
sub strip_result {
	my ( $html ) = @_;
	$html =~ m {
			<div\sid="container">
			(.*?)
			<p\sid="page">
	}sgix;
	return $1;
}
sub parse_item {
	my $html = shift;
	my $aoh = [];
    $html =~ m {
        <h3\sclass=(?:"t"|t)
        (?:.*?)>
		<a
		(?:.*?)
		href="(.*?)"	#url
		(?:.*?)
		>
		(.*?)			#title
		</a>
		(?:.*?)
		<font\ssize=(?:"-1"|-1)>
        (.*)			#content
    }sgix;
    my ($t1,$t2,$t3) = ($1,$2,$3);
    push (@{$aoh}, $t1,$t2,$t3);
	return $aoh;
}
sub strip_tag
{
	my $str = shift;
	return '' unless $str;

	$str =~ s/<(?:.*?)>//g if ($str=~m"<");
	$str =~ s/<\/.*?>//g if ($str=~m"</");
	$str =~ s/<script.*?>.*?<\/script>//sg if ($str=~"<script");
	return $str;
}

sub parse_result
{
    my ($html) = @_;
    my $aoh = [];
    while ($html =~ m {
    	<table
		(?:.*?)
        class="(?:result-op|result)"
        (?:.*?)>
		<td\sclass=(?:"f"|f)
		(?:.*?)
		>
        (.*?)			#content
		</td>
		(?:.*?)
		</table>
    }sgix) {
	   #$t = $1;
	   #$t =~ s/<\S[^<>]*(?:>|$)//gs;
       push (@{$aoh}, $1);
    }
    return $aoh;
}
