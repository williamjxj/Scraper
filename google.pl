#!/opt/lampp/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe -w

use lib qw(./lib/);
use config;
use db;
use google;

use warnings;
use strict;

use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use constant FURL => q{http://www.google.com};
use constant KEYFILE => q{./keywords.txt};

sub BEGIN
{
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	$ENV{'PATH'} = '/usr/bin/:/bin/:.';
	local ($|) = 1;
	undef $/;
}

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

# 2 mech are created, 1 for google, 1 for detail website.
our ( $mech, $mech1) = ( undef, undef );
our ( $gpm, $log ) = ( undef, undef );
our ( $db, $dbh, $sth ) = ( undef, undef, undef );
my @blacklist = ('google', 'wikipedia');

$db = new db( USER, PASS, DSN.":hostname=".HOST );
$dbh = $db->{dbh};

$gpm = new google( $db->{dbh} );

$log = $gpm->get_filename(__FILE__);
$gpm->set_log($log);
$gpm->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $html, $detail, $web ) = ( '', [], undef );
my ( $all_links, $url ) = ( [], FURL );
my ( $keyword, $kfile, $debug ) = ( undef, undef, 0 );
my ( $page_url, $cate_id ) = ('', 3);


$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );
$mech1->timeout( 20 );

GetOptions(
		'web=s' => \$web,
		'keyword=s' => \$keyword,
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

# read keywords.txt first line (without ^#).
unless ($keyword) {
	local ($/) = "\n";
	$kfile = new FileHandle(KEYFILE, 'r') or die $!;
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
}
$keyword = 'china food negative news' unless (defined $keyword && $keyword);


$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, num => 100 }
);
$mech->success or die $mech->response->status_line;

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

$mech->get( $page_url );
$mech->success or die $mech->response->status_line;

my $t = $gpm->strip_result( $mech->content );
my $aoh = $gpm->parse_result($t);
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

	$garef = $gpm->parse_url( $mech1->content );
	# print Dumper( $garef );

	$html = $mech1->content;

	# after parse homepage of the website, search email/phone.
	$detail = $gpm->get_detail( $html );

	print Dumper($detail);
	next if($detail eq '' );
	$detail = $dbh->quote($detail);
	
	$title = $dbh->quote($garef->[0] );
	$description = $dbh->quote($garef->[1]);
	$keywords = $dbh->quote($garef->[2] );

	$sth = $dbh->do( qq{ insert ignore into foods
		(google_keywords, meta_description, meta_keywords, title, url, summary, fdate, cate_id, detail) 
		values( '$keyword', $description, $keywords, $title, '$link', $summary, now(), $cate_id, $detail)
	});

	undef( @{$garef} );
	undef( @{$detail} );
	$mech1->back;
}

$dbh->disconnect();

$end_time = time;
$gpm->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$gpm->close_log();

exit 6;

