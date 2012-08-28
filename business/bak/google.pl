#!/usr/bin/perl -w

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use lib qw(../lib/);
use google_config;
use db;
use google;

local ($|) = 1;
undef $/;

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

our ( $mech, $db, $dbh, $sth ) = ( undef, undef, undef, undef );
our ( $g, $log ) = ( undef, undef );
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$g = new google( $db->{dbh} );

$log = $g->get_filename(__FILE__);
$g->set_log($log);
$g->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $keyword, $fd, $file, $debug ) = ( 'martial arts studio', undef, undef, 0 );
my ( $html, $detail, $web, $reason ) = ( '', [], '', undef, undef );
my ( $all_links, $url, $count ) = ( [], '', 0 );
my ($page_url) = ('');

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout(30);

GetOptions( 'web=s' => \$web, 'keyword=s' => \$keyword, 'file' => \$file, 'debug' => \$debug );

if ($debug) {
	$g->{web_flag} = '1';
}

if ($web) {
	$mech->get( $web );
	$mech->success or die $mech->response->status_line;

	$detail = $g->get_detail( $mech->content );
	print Dumper( $detail );
	exit;
}

if ($keyword) {
	$keyword = 'martial arts vedio';
}
else {
	# $fd = new FileHandle(KEYWORD_FILE, 'w');
	# $keyword = <$fd>;
}

$url = 'http://www.google.com';
if ($file) {
	$file = new FileHandle('../public_html/g6.html', 'w');
}

$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

$mech->submit_form(
    form_name => 'f',
        fields      => { q => $keyword, }
);
$mech->success or die $mech->response->status_line;

# print $mech->content;
# print $mech->uri . "\n";

my $paref = $g->parse_next_page( $mech->content );
print Dumper($paref);
$page_url = $paref->[1];

LOOP:

my $aoh = $g->parse_result( $g->strip_result( $mech->content ));
# print Dumper($aoh);

my $garef = [];
my ($description, $keywords, $title, $title1, $summary, $email, $phone, $fax, $link, $zip);
my $valid = 'N';
foreach my $r (@{$aoh}) {

	$link = $r->[0];
	$title1 = $dbh->quote($r->[1]);
	$summary = $dbh->quote($r->[2]);
	print "-------------------------\n";
	print $link . "\n";

	$mech->get( $link );
	$mech->success or next;

	$garef = $g->parse_url( $mech->content );
	# print Dumper( $garef );

	$html = $mech->content;

	# after parse homepage of the website, search email/phone.
	$detail = $g->get_detail( $html );

	unless (ref $detail && $detail->[0]) {
		if ($html =~ m/\<frameset/i) {
			my $surls = $g->get_frameset( $html );
		}
		else {
			$mech->follow_link( text_regex => qr/(contact|about)/i );
			# $mech->success or die $mech->response->status_line;
			unless ($mech->success ) {
				print $mech->response->status_line . "\n";
				next;
			}
=comment
			if (defined $file) {
				print $file $mech->content;
				$file->close;
			}
=cut
			$detail = $g->get_detail($mech->content);
			$mech->back;
		}
	}
	print Dumper($detail);

	# Only the record with email is saved.
	if ( defined $detail->[0] &&  $detail->[0] ) {
		$title = $dbh->quote($garef->[0] );
		$description = $dbh->quote($garef->[1]);
		$keywords = $dbh->quote($garef->[2] );
		$email = $dbh->quote( $detail->[0] );
		$phone = $dbh->quote( $detail->[1] );
		$fax = $dbh->quote( $detail->[2] );
		$zip = $dbh->quote( $detail->[3] );
		$sth = $dbh->do( q{ insert ignore into } . CONTACTS . qq{ (meta_description, meta_keywords, title, title1, url, phone, fax, email, zip, valid, summary, date) 
			values( $description, $keywords, $title, $title1, '$link', $phone, $fax, $email, $zip, '$valid', $summary, now() )
		});
	}
	undef( @{$garef} );
	undef( @{$detail} );
	$mech->back;
}

if ($page_url)
{
	print "..........: [" . $page_url . "]\n";
	$page_url = $url . $page_url;
	$page_url =~ s/start=\d+/start=50/;
	print $page_url . "\n";

    $mech->get( $page_url );
    # $mech->follow_link( url => $page_url );
    $mech->success or die $mech->response->status_line;

    $paref = $g->parse_next_page( $mech->content );
	print Dumper($paref);

    $page_url = $paref->[1];


    $mech->get( $page_url );
    # $mech->follow_link( url => $page_url );
    $mech->success or die $mech->response->status_line;

    $paref = $g->parse_next_page( $mech->content );
	print Dumper($paref);

	if (defined $file) {
		print $file $mech->content;
		$file->close;
		exit;
	}
	goto LOOP if ($page_url);
}

$dbh->disconnect();

$end_time = time;
$g->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$g->write_log("----------------------------------------------\n");
$g->close_log();

exit 6;

