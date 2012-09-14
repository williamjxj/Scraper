#!/opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use LWP::Simple;
use DBI;
use Getopt::Long;

use lib qw(../lib/);
use config;
use db;
use baidu;

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";

our $dbh = new db( $user, $pass, $dsn );

my @blacklist = ('google', 'wikipedia');

our ( $mech, $mech1) = ( undef, undef );

our ($bd, $url) = ();

my $h = {
	'category' => '',
	'cate_id' => 0,
	'item' => '',
	'item_id' => 0,
	'createdby' => $dbh->quote($bd->get_os_stripname(__FILE__)),
};


$bd = new baidu($dbh);

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );
$mech1->timeout( 20 );


$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

$mech->submit_form(
    'form_name' => 'f',
	'fields'    => { q => $keyword, num => 100 }
);
$mech->success or die $mech->response->status_line;

my($page_url, $paref);

$paref = $bd->parse_next_page( $mech->content );
print Dumper( $paref );
$page_url = $paref->[1];

# very imporant.
$page_url =~ s/\&amp;/\&/g if ($page_url=~m/&amp;/);
# $page_url =~ s/search\?/#/;
$page_url = $url . $page_url;

my $garef = [];
my ($description, $keywords, $title, $summary, $email, $phone, $fax, $link, $zip);

LOOP:

$mech->get( $page_url );
$mech->success or die $mech->response->status_line;

my $t = $bd->strip_result( $mech->content );
my $aoh = $bd->parse_result($t);
#print Dumper($aoh);

foreach my $r (@{$aoh}) {

	$link = $r->[0];
	$summary = $r->[1] . ': ' . $r->[2];
	$summary = $dbh->quote( $summary );
	print "-------------------------\n";
	print $link . "\n";

	if (grep{ $link =~ m{$_}i } @blacklist) {
		next;
	}

	$mech1->get( $link );
	$mech1->success or next;

	$garef = $bd->parse_url( $mech1->content );

	my ($html, $detail, $title, $sth);
	$html = $mech1->content;

	# after parse homepage of the website, search email/phone.
	$detail = $bd->get_detail( $html );

	print Dumper($detail);
	next if($detail eq '' );
	$detail = $dbh->quote($detail);
	
	$title = $dbh->quote($garef->[0] );
	$description = $dbh->quote($garef->[1]);
	$keywords = $dbh->quote($garef->[2] );

	my $category = $self->{dbh}->quote($rank->[2]);
	my $item = $self->{dbh}->quote($rank->[0]);

	my $sql = qq{ insert into t_baidu
		(title,
		url,
		pubDate,
		source, 
		author, 
		category,
		cate_id,
		item,
		item_id,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubDate'},
		$h->{'source'}, 
		$h->{'author'},
		$category,
		$h->{'cate_id'},
		$item,
		$h->{'item_id'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)
	on duplicate key update
		content = $h->{'desc'},
		pubDate = $h->{'pubDate'}
	};
	$self->{dbh}->do($sql);

	undef( @{$garef} );
	$mech1->back;
}

$dbh->disconnect();
