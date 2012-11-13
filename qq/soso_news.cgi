#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'gb2312';
use WWW::Mechanize;
use CGI qw(:standard);
use Encode;

#binmode(STDIN, ":encoding(utf8)");
#binmode(STDOUT, ":encoding(gb2312)");

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use soso;

use constant SURL => q{http://news.soso.com/};

#print header(-charset=>'gb2312');
print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');
Encode::decode("gb2312", $keyword);
#Encode::_utf8_on($keyword);

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


$ss->write_file('soso.html', $mech->content);

#print $mech->content;

#my $t = $ss->strip_result( $mech->content );
#echo $t;

exit 6;


###########################
#
sub strip_result
{
	my ( $html ) = @_;
	$html =~ m {
			<div\sid="result"
			.*?
			<ol\s*>
			(.*?)	#soso用ol->li来划分每条记录
			</ol>
	}six;
	return $1;
}

sub parse_result
{
    my ( $self, $html ) = @_;
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
        <p\sclass="ds">
        (.*?)	#3.正文
        </p>
        (?:.*?)
        <cite>
        (.*?)	#4.日期和网址
        </cite>
    }sgix) {
        my ($t1,$t2,$t3,$t4) = ($1,$2,$3,$4);
        my @url_date = $t4 =~ m/(.*?)(?:\s|-|\.{1,3})(.*)/;
        push (@{$aoh}, [$t1,$t2,$t3,$url_date[0], $url_date[1]]);
    }
    return $aoh;
}


# 相关搜索。
sub strip_related_keywords
{
	my ( $self, $html ) = @_;
	$html =~ m{
		<div
		(?:.*?)
		id="rel"
		.*?
		>
		(.*?)
		<div\sid="bSearch"
	}six;
	return $1;
}
sub get_related_keywords
{
	my ( $self, $html ) = @_;
	return unless $html;
	my $aoh;
	
	while($html =~ m{
		<a
		(?:.*?)
		href="
		(.*?)		#链接地址
		">
		(.*?)		#关键词
		</a>
	}sgix) {
		my ($t1, $t2) = ($1, $2);
		push (@{$aoh}, [$t1, $t2]);
	}
	return $aoh;
}


1;
