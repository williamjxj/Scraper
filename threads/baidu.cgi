#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf8';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode qw(decode encode);

#binmode(STDIN, ":encoding(utf8)");
binmode(STDOUT, ":encoding(utf8)");

use constant SURL => 'http://www.baidu.com';

print header(-charset=>"UTF-8"); #print "Content-type: text/html; charset=utf-8\n\n";

my $q = CGI->new;
my $keyword = $q->param('q');
$keyword .= ' 负面新闻';
Encode::decode("gbk", $keyword);
Encode::_utf8_on($keyword);

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
