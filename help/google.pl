#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use lib qw(../lib/);
use config;
use db;
use google;

local ($|) = 1;
undef $/;

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

####################################################################
# 2 mech are creatd, 1 for google, 1 for detail website.
####################################################################
our ( $mech, $mech1) = ( undef, undef );
our ( $gpm, $log ) = ( undef, undef );
our ( $db, $dbh, $sth ) = ( undef, undef, undef );
my @blacklist = (
	'yelp.com', 'yellowpages', 'google', 'wikipedia',
	'superpages', 'informationpages',
	'backpage', 'craigslist', 'facebook',
);

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$gpm = new google( $db->{dbh} );

$log = $gpm->get_filename(__FILE__);
$gpm->set_log($log);
$gpm->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

# kwyword='martial arts studio
my ( $html, $detail, $web, $reason ) = ( '', [], '', undef, undef );
my ( $all_links, $url ) = ( [], URL );
my ( $keyword, $kds, $kfile, $ofile, $debug ) = ( undef, undef, undef, undef, 0 );
my ( $page_url, $all, $city, $region, $country ) = ('', undef, undef, undef, undef );
my $valid = 'N';

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );
$mech1->timeout( 20 );

=comment
input:
web: website to debug
city: city to add into keywords: 'martial arts studio chicago'
all: list all cities from us/ca craig/kijiji.
keyword: read from keywords.txt, default is 'martial arts studio'
ofile: why google can't pagination?
debug: output flag for intermedia processing.
sample:
>>google.pl -w http://yahoo.com -k -l -a 1-9 -c 'chicago' -d -o
=cut
GetOptions(
		'web=s' => \$web,
		'city=s' => \$city,
		'log' => \$log,
		'all=s' => \$all,
		'keyword=s' => \$keyword,
		'ofile' => \$ofile,
		'debug' => \$debug,
	 );

if ($debug) {
	$gpm->{web_flag} = '1';
}

# for test purpose
if ($web) {
	$mech->get( $web );
	$mech->success or die $mech->response->status_line;
	$detail = $gpm->get_detail( $mech->content );
	print Dumper( $detail );
	exit 1;
}

# the $all might be: 1,2,3,4,5,6,7,8,9.
if ($all) {
	my $cities = [];
	if( $all=~m/[0-9]/ ) {
		$cities = $gpm->select_store_finder_cities($all);
	}
	else {
		die("Please input -a from 1-9.");
	}
    foreach my $cy (@$cities) {
        print $cy->[0]."\n";
        #print $cy->[0] . ', [' . $cy->[1] . "]\n";
    }
    exit 2;
}

# read keywords.txt first line (without ^#).
unless ($keyword) {
	local ($/) = "\n";
	$kfile = new FileHandle(KEYWORD_FILE, 'r') or die $!;
	my @lines = <$kfile>;
	foreach my $line (@lines) {
		chomp($line);
		if ($line !~ m/^#/) {
			$keyword = $line;
			last;
		}
	}
	$kfile->close;
	die unless ($keyword);
	undef $/;
}
$keyword = KEYWORD unless (defined $keyword && $keyword);

if ($city) {
	$city = ucfirst(lc($city));
	$kds = $keyword . ' ' . $city;
	my $rc = $gpm->get_region_country($city);
	$region = ucfirst(lc($rc->[0]));
	$country = uc($rc->[1]);
}
else {
	$kds = $keyword;
}

if ($ofile) {
	$ofile = new FileHandle(OFILE, 'w') or die $!;
}

$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

$mech->submit_form(
    form_name => 'f',
	fields    => { q => $kds, num => 100 }
);
$mech->success or die $mech->response->status_line;

# print $mech->content;
# print $mech->uri . "\n";

my $paref = $gpm->parse_next_page( $mech->content );
print Dumper( $paref );
$page_url = $paref->[1];

# very imporant.
$page_url =~ s/\&amp;/\&/g if ($page_url=~m/&amp;/);
# $page_url =~ s/search\?/#/;
$page_url = $url . $page_url;

my $garef = [];
my ($description, $keywords, $title, $summary, $email, $phone, $fax, $link, $zip);

LOOP:

my $aoh = $gpm->parse_result( $gpm->strip_result( $mech->content ));
print Dumper($aoh);

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

	$garef = $gpm->parse_url( $mech1->content );
	# print Dumper( $garef );

	$html = $mech1->content;

	# after parse homepage of the website, search email/phone.
	$detail = $gpm->get_detail( $html );

	unless (ref $detail && $detail->[0]) {
		my $surl = undef;
		if ($html =~ m/\<frameset/i) {
			$surl = $gpm->get_frameset( $html );
			if ($surl) {
				$mech1->follow_link( url => $surl );
				unless ($mech1->success ) {
					print $mech1->response->status_line . "\n";
					next;
				}
			}
		}
		$mech1->follow_link( text_regex => qr/(contact|about)/i );
		# $mech1->success or die $mech1->response->status_line;
		unless ($mech1->success ) {
			print $mech1->response->status_line . "\n";
			next;
		}
		$detail = $gpm->get_detail($mech1->content);
		$mech1->back;
	}

	# Only the record with email is saved.
	if ( defined $detail->[0] &&  $detail->[0] ) {

		print Dumper($detail);
		$title = $dbh->quote($garef->[0] );
		$description = $dbh->quote($garef->[1]);
		$keywords = $dbh->quote($garef->[2] );
		$email = $dbh->quote( $detail->[0] );
		$phone = $dbh->quote( $detail->[1] );
		$fax = $dbh->quote( $detail->[2] );
		$zip = $dbh->quote( $detail->[3] );

		$valid = 'Y' if ($detail->[1] && $detail->[2]);
		$city = '' unless (defined $city);
		$region = '' unless (defined $region);
		$country = '' unless (defined $country);

		$sth = $dbh->do( q{ insert ignore into } . CONTACTS . qq{
			(google_keywords, meta_description, meta_keywords, title, url, phone, fax, email, zip, valid, summary, date, city, region, country) 
			values( '$keyword', $description, $keywords, $title, '$link', $phone, $fax, $email, $zip, '$valid', $summary, now(), '$city', '$region', '$country' )
		});
	}
	undef( @{$garef} );
	undef( @{$detail} );
	$mech1->back;
}

=comment
if ($page_url)
{
    # not work: $mech->get( $page_url );
    $mech->follow_link( url => $page_url );
    $mech->success or die $mech->response->status_line;

    $paref = $gpm->parse_next_page( $mech->content );
	print Dumper($paref);
    $page_url = $paref->[1];

	$page_url =~ s/\&amp;/\&/g;
	$page_url =~ s/search\?/#/ if ($page_url=~m/search\?/);
	$page_url = $url . $page_url if ($page_url!~m/http/);
	print "..........: [" . $page_url . "]\n";

	goto LOOP;

    $mech->get( $page_url );
    # $mech->follow_link( url => $page_url );
    $mech->success or die $mech->response->status_line;

    $paref = $gpm->parse_next_page( $mech->content );
	print Dumper($paref);

}
=cut

if (defined $ofile) {
	# print $ofile $mech->content;
	$ofile->close;
	exit;
}

$dbh->disconnect();

$end_time = time;
$gpm->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$gpm->write_log("----------------------------------------------\n");
$gpm->close_log();

exit 6;

