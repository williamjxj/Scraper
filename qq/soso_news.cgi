#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf-8';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

#binmode(STDIN, ":encoding(utf8)");
binmode(STDOUT, ":encoding(utf8)");

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use soso;

use constant SURL => q{http://news.soso.com/};

#print header(-charset=>'gb2312');
print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

Encode::decode("gb2312", $keyword);
Encode::_utf8_on($keyword);

my $ss = new soso();

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'flpage',
	fields    => { 
		ty => 'c',
		w => $keyword
	}
);
$mech->success or die $mech->response->status_line;

$ss->write_file('soso.html', $mech->content);

#print $mech->content;

my $html = strip_result( $mech->content );

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 6;

###########################
#
sub strip_result
{
	my ( $html ) = @_;
	$html =~ m {
			<div\sid="result"
			.*?
			<ol\sid="result_list">
			(.*?)	#soso用ol->li来划分每条记录
			</ol>
	}six;
	return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
	while ($html =~ m {
		<li
		.*?
		href="
		(.*?)	#1.链接地址
		"
		(?:.*?)
		>
		(.*?)	#2.标题
        </a>
        (?:.*?)
        <span(?:.*?)>
        (.*?)	#3.正文
        </span>
        (?:.*?)
        </li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
