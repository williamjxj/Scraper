#!/usr/bin/perl

use strict;
use warnings;
use utf8;
#use encoding 'utf8';
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

print header(-charset=>"UTF-8");

use constant SURL => q{http://cn.search.yahoo.com/};

my $q = CGI->new;
my $keyword = $q->param('q');
$keyword .= ' 负面新闻';
Encode::_utf8_on($keyword);

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_id => 'sbox1',
	fields    => {
		q => $keyword,
		oq => $keyword,
		bs => ''
	}
);
$mech->success or die $mech->response->status_line;

my $t = strip_result( $mech->content );

my $aoh = parse_result($t);

#my $json = JSON->new->allow_nonref;
#my $text = $json->encode($aoh);

my $text = encode_json $aoh;
print $text;

exit 9;

###########################################
sub strip_result
{
	my ( $html ) = @_;

	my $striped_html = undef;
	$html =~ m {
			<ul\sclass="results">
			(.*?)
			<div\sclass="page">
	}sgix;
	return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
	while ($html =~ m {
		<li\sclass=(?:"record|record)
		(?:.*?)
		<h3\sclass="title"
		(?:.*?)
		href="
		(.*?)	#1.���ӵ�ַ
		"
		(?:.*?)
		>
		(.*?)	#2.����
        </a>
        (?:.*?)
        <div (?:.*?) >
        (.*?)	#3.����
		</div>	
		(?:.*?)
		<span\sclass="date">
		(.*?)
		</span>
		(?:.*?)
        </li>
    }sgix) {
        my ($t1,$t2,$t3,$t4) = ($1,$2,$3,$4);
		$t1 =~ s/^\/url\?q=//  if($t1 =~ m/^\/url/);
		$t1 =~ s/\&sa=.*$//  if($t1 =~ m/\&sa=/);
		$t2 =~ s/\<em>//g if ($t2=~m/\<em>/);
		$t2 =~ s/\<\/em>//g if ($t2=~m/\<\/em>/);
		$t2 =~ s/\<b>\.+\<\/b>//s;
		$t3 =~ s/\<br>.*$//sg;
		$t3 =~ s/\<b>\.\.\.\<\/b>/.../sg;
		$t3 =~ s/\<.*?>//sg;
		my $t = $t2 . ' (' . $t4 . ')';
        push (@{$aoh}, [$t1,$t,$t3]);
    }
    return $aoh;
}

