#!/usr/bin/perl

use lib qw(../lib/);

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use google_config;
use db;
use google;

local ($|) = 1;
undef $/;

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

our ( $gpm, $log ) = ( undef, undef );
our ( $db, $dbh, $sth ) = ( undef, undef, undef );
our @blacklist = (
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
my ( $html, $web ) = ( '', undef );
my ( $keyword, $kds, $kfile, $ofile, $debug ) = ( undef, undef, undef, undef, 0 );
my ( $all, $city, $region, $country ) = (undef, undef, undef, undef );
my ($aoh, $garef, $detail, $emails) = ([], [], [], []);
my ($description, $keywords, $title, $summary, $email, $phone, $fax, $link, $zip);
my ( $url, $valid, $id ) = ( URL, 'N', 0);

####################################################################
# 2 mech are creatd, 1 for google, 1 for detail website.
####################################################################
our ( $mech, $mech1) = ( undef, undef );
$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );
$mech1->timeout( 20 );

GetOptions(
		'city=s' => \$city,
		'web=s' => \$web,
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

# the $all might be: 1,2,3,4,5,6,7,8,9,10.
#print $cy->[0] . ', [' . $cy->[1] . "]\n";
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
	my $rc = $gpm->get_region_country($city);
	$region = ucfirst(lc($rc->[0]));
	$country = uc($rc->[1]);
	$kds = $keyword . ' ' . $city;
}
else {
	$kds = $keyword;
}

if ($ofile) {
	$ofile = new FileHandle(OFILE, 'w') or die $!;
}


########### Start from here... ################
# 1. from entry point: google.com.
###############################################
$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n" if($gpm->{web_flag});

# 2. submit the keyword.
$mech->submit_form(
    form_name => 'f',
	fields    => { q => $kds, num => 100 }
);
$mech->success or die $mech->response->status_line;

# 3. get 100 results, parse it.
# strip to get content to make it smaller, then parts the result lists.
$aoh = $gpm->parse_result( $gpm->strip_result( $mech->content ));
print Dumper($aoh)  if($gpm->{web_flag});

# 4. for the array of array, process each record.
foreach my $r (@{$aoh}) 
{
	$link = $r->[0];
	if (grep{ $link =~ m{$_}i } @blacklist) {
		next;
	}

	$summary = $r->[1] . ': ' . $r->[2];
	$summary = $dbh->quote( $summary );
	print "--------------[" . $link . "]---------------\n"  if($gpm->{web_flag});

	$mech1->get( $link );
	$mech1->success or next;

	# 5. for each individual web, parse 'title', 'meta keywords', 'meta description'.
	$garef = $gpm->parse_url( $mech1->content );
	# print Dumper( $garef )  if($gpm->{web_flag});

	$html = $mech1->content;

	# 6. after parse homepage of the website, parse email,phone,fax,zip.
	$detail = $gpm->get_detail( $html );

	# 7. if email not exist, following the link 'contact' to search sub-pages.
	if  (ref $detail && $detail->[0]) {
		$emails = $gpm->get_emails( $html );
	}
	else {
		# 8. frameset? follow to next page if have.
		if ($html =~ m/\<frameset/i) {
			my $surl = $gpm->get_frameset( $html );
			if ($surl) {
				$mech1->follow_link( url => $surl );
				unless ($mech1->success ) {
					print $mech1->response->status_line . "\n";
					next;
				}
			}
		}

		# 9. if having 'contact' or 'about' link, follow to it.
		$mech1->follow_link( text_regex => qr/(contact|about)/i );
		unless ($mech1->success ) {
			print $mech1->response->status_line . "\n";
			next;
		}

		# 10. no matter which page reaches, findemail, phone, fax, zip.
		$detail = $gpm->get_detail($mech1->content);

		if  (ref $detail && $detail->[0]) {
			$emails = $gpm->get_emails( $mech1->content );
		}
		$mech1->back;
	}

	# 11. if detail array includes email?
	# Only the record with email is saved.
	if ( defined $detail->[0] &&  $detail->[0] )
	{
		print Dumper($detail)  if($gpm->{web_flag});

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

		# 15. patch: operate biz_google_email table.
		if (ref $emails && (scalar(@{$emails})>0)) {
			$id =  $gpm->get_last_id( $detail->[0] );
			$emails = $gpm->uniq_links( $emails );
			print Dumper($emails) if ($gpm->{web_flag});

			foreach my $e (@{$emails}) {
				next unless ($e);
				$e = $dbh->quote( $e );
				$sth = $dbh->do( q{ insert ignore into } . EMAILS . qq{ (contact_id, email, url, date) values( $id, $e, '$link', now() ) });
			}
		}
	}

	# 16. graceful clear memory.
	undef( @{$garef} );
	undef( @{$detail} );
	$garef = undef;
	$detail = undef;
	$mech1->back;
}

if (defined $ofile && $ofile) {
	# print $ofile $mech->content;
	$ofile->close;
	exit;
}
$dbh->disconnect();
$end_time = time;
$gpm->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$gpm->write_log("----------------------------------------------\n");
$gpm->close_log();

exit 8;

