#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use CGI qw(:standard);
use JSON;
use Encode;
use Data::Dumper;

use constant SURL => q{http://cn.search.yahoo.com/};

print header(-charset=>"UTF-8");

my $q = CGI->new;
my $keyword = $q->param('q');
#decode("utf-8", $keyword);
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

#write_file('yahoo.html', $mech->content);

my $t = strip_result( $mech->content );

my $aoh = parse_result($t);

# print Dumper($aoh);

my $json = JSON->new->allow_nonref;

#my $text = encode_json $aoh;

my $text = $json->encode($aoh);

print $text;
exit 9;

###########################################
sub strip_result
{
	my ( $self, $html ) = @_;

	my $striped_html = undef;
	$html =~ m {
			<div\sid="main">
			(.*?)
			<div\sid="right">
	}sgix;
	return $1;
}

sub parse_result
{
    my ( $self, $html ) = @_;
    return unless $html;
    my $aoh = [];    
	while ($html =~ m {
		<div\sclass=(?:"res"|res)
		(?:.*?)
		<h3>
		(?:.*?)
		href="
		(.*?)	#1.链接地址
		"
		(?:.*?)
		>
		(.*?)	#2.标题
        </a>
        (?:.*?)
        <div\sclass="abstr"
        (?:.*?)
        >
        (.*?)	#3.正文
        </div>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t1 =~ s/^\/url\?q=//  if($t1 =~ m/^\/url/);
		$t1 =~ s/\&sa=.*$//  if($t1 =~ m/\&sa=/);
		$t2 =~ s/\<em>//g if ($t2=~m/\<em>/);
		$t2 =~ s/\<\/em>//g if ($t2=~m/\<\/em>/);
		$t2 =~ s/\<b>\.+\<\/b>//s;
		$t3 =~ s/\<br>.*$//sg;
		$t3 =~ s/\<b>\.\.\.\<\/b>/.../sg;
		$t3 =~ s/\<.*?>//sg;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}

