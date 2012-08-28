#!/usr/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe
## if (grep{ $_ =~ m#$turl#i } @deposits) 

use lib qw(../lib);
use business_config;
use db;
use bb;

use warnings;
use strict;
use Data::Dumper;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

local ($|) = 1;
undef $/;

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

our ( $mech, $db, $biz, $log ) = ( undef, undef );
our ( $dbh, $sth );
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$biz = new bb( $db->{dbh} );

$log = $biz->get_filename(__FILE__);
$biz->set_log($log);
$biz->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $webs, $succeed, $web ) = ( [], 0, '' );
my ( $html, $emails, $id, $email, $url, $reason ) = ( '', [], 0, undef, undef, undef );
my ( $all_links, $aurl ) = ( [], '' );

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout(10);

GetOptions( 'web=s' => \$web );

if ($web) {
	$webs = [[$web]];
	$biz->{web_flag} = '1';
}
else {
	$webs = $biz->select_category('1');
}

foreach my $url_ary ( @{$webs} ) 
{
	$url = $url_ary->[0];
	$url = 'http://' . $url if ($url !~ m/^http/);
	$succeed = 0;

	if ($web) {
		$id = $biz->get_id($web);
	}
	else {
		$id = $url_ary->[1];
	}
	print "---------------------------------------------------\n[" . $url . "], [" . $id . "]\n";

	$mech->get( $url );

	# 1. get not successful:
	# If not successful, set accessible='N', and content with reason.
	if (! $mech->success ) {
		$reason = $dbh->quote( $mech->response->status_line );
		$sth = $dbh->do( q{ update } . CONTACT . qq{ set accessible = 'N', content=$reason,  date = now() where id = $id; });
		print $reason;
		next;
	}

	# 2. get successful: search emails in homepage.
	$html = $mech->content;

	$emails = $biz->get_emails($html);
	print Dumper($emails) if ($web);

	if (scalar @{$emails} > 0) {

		foreach my $e (@{$emails}) {
			$e = $dbh->quote( $e );
			$sth = $dbh->do( q{ insert ignore into } . EMAIL . qq{ (contact_id, email, url, date) values( $id, $e, '$url', now() ) });
		}
		$sth = $dbh->do( q{ update } . CONTACT . qq{ set have_email = 'Y', date = now() where id = $id; });
		$succeed = 1;
		next;
	}

	if ($html =~ m/\<frameset/i) {
		$sth = $dbh->do( q{ update } . CONTACT . qq{ set accessible = 'N', content='frameset',  date = now() where id = $id; });
		print "Frameset, quit.\n" if ($web);
		next;
	}

	$all_links =  $biz->get_hrefs($html);
	$all_links = $biz->uniq($all_links);
	print Dumper($all_links) if ($web);

	foreach my $turl ( @{$all_links} ) {
		next if $turl eq '/';

		$mech->follow_link( url => $turl );
		$mech->success or next;

		$emails = $biz->get_emails($mech->content);
		print Dumper($emails) if ($web);

		if (scalar @{$emails} > 0) {

			foreach my $e (@{$emails}) {
				$e = $dbh->quote( $e );
				if ($turl =~ m#^/#) {
					$aurl = $url . $turl;
				}
				else {
					if( ($turl=~m/^http:/i) || ($turl=~m/www\./) || ($turl=~m/\.com/) ) {
						$aurl = $turl;
					}
					else {
						$aurl = $url . '/' . $turl;
					}
				}
				print ":::::[" . $aurl . "]\n" if ($web);
				$aurl = $dbh->quote( $aurl );
				$sth = $dbh->do( q{ insert ignore into } . EMAIL . qq{ (contact_id, email, url, date) values( $id, $e, $aurl, now() ) });
			}
			$sth = $dbh->do( q{ update } . CONTACT . qq{ set have_email = 'Y', date = now() where id = $id; });
			$succeed = 1;
			last;
		}
	}
	unless ($succeed) {
		# At last, mark it processed.
		$sth = $dbh->do( q{ update } . CONTACT . qq{ set accessible='N', content='first loop not find email.', date = now() where id = $id; });
	}
}

$dbh->disconnect();

$end_time = time;
$biz->write_log( "Total days' data : [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$biz->write_log("----------------------------------------------\n");
$biz->close_log();

exit 8;

