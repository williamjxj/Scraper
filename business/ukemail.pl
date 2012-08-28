#!/usr/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe
## if (grep{ $_ =~ m#$turl#i } @deposits) 

use lib qw(../lib);
use business_config;
use db;
use ukbusiness;

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

$biz = new ukbusiness( $db->{dbh} );

$log = $biz->get_filename(__FILE__);
$biz->set_log($log);
$biz->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $webs, $succeed, $web, $seq, $debug ) = ( [], 0, '', '', '' );
my ( $html, $emails, $id, $email, $url, $reason ) = ( '', [], 0, undef, undef, undef );
my ( $all_links, $aurl, $pemail, $count ) = ( [], '', '', 0 );

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout(10);

GetOptions( 'web=s' => \$web, 'seq' => \$seq, 'debug' => \$debug );

if ($web) {
	$webs = [[$web]];
}
else {
	if ($seq)  {
		$webs = $biz->select_category('1');
	}
	else {
		$webs = $biz->select_category();
	}
}
if ($debug) {
	$biz->{web_flag} = '1';
}

foreach my $url_ary ( @{$webs} ) 
{
	$url = $url_ary->[0];
	$url = 'http://' . $url if ($url !~ m/^http/);
	$succeed = 0;

	if ($web) {
		$id = $biz->get_id($web);
		unless ($id) {
			print 'No Id found. Quit...';
			die;
		}
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
		$sth = $dbh->do( q{ update } . UKCONTACTS . qq{ set accessible = 'N', reason=$reason,  date = now() where id = $id; });
		print $reason;
		next;
	}

	# 2. get successful: search emails in homepage.
	$html = $mech->content;

	$emails = $biz->get_emails($html);

	if (ref $emails && (scalar(@{$emails})>0)) {
		$emails = $biz->uniq_links( $emails );
		$count = scalar(@{$emails});
		$pemail = $dbh->quote($emails->[0]);

		print Dumper($emails) if ($debug);

		foreach my $e (@{$emails}) {
			$e = $dbh->quote( $e );
			$sth = $dbh->do( q{ insert ignore into } . UKEMAILS . qq{ (contact_id, email, url, date) values( $id, $e, '$url', now() ) });
		}
		$sth = $dbh->do( q{ update } . UKCONTACTS . qq{ set primary_email=$pemail, total_emails=$count, have_email='Y', date=now() where id = $id; });
		$succeed = 1;
		next;
	}

	if ($html =~ m/\<frameset/i) {
		$sth = $dbh->do( q{ update } . UKCONTACTS . qq{ set accessible = 'N', reason='frameset',  date = now() where id = $id; });
		print "Frameset, quit.\n" if ($debug);
		next;
	}

	$all_links =  $biz->get_hrefs($html);
	$all_links = $biz->uniq_links( $all_links );
	print Dumper($all_links) if ($debug);

	foreach my $turl ( @{$all_links} )
	{
		next if $turl eq '/';

		$mech->follow_link( url => $turl );
		$mech->success or next;

		$emails = $biz->get_emails($mech->content);

		if (ref $emails && (scalar @{$emails} > 0)) {
LOOP:
			$emails = $biz->uniq_links( $emails );
			print Dumper($emails) if ($debug);

			$count = scalar @{$emails};
			$pemail = $dbh->quote($emails->[0]);
			$reason = 'find email in aaa ' . __FILE__ . '['. __LINE__ . ']' unless ($reason);
			$reason = $dbh->quote( $reason );

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
				print ":::::[" . $aurl . "]\n" if ($debug);
				$aurl = $dbh->quote( $aurl );
				$sth = $dbh->do( q{ insert ignore into } . UKEMAILS . qq{ (contact_id, email, url, date) values( $id, $e, $aurl, now() ) });
			}
			$sth = $dbh->do( q{ update } . UKCONTACTS . qq{ set primary_email=$pemail, reason=$reason, total_emails=$count, have_email='Y', date=now() where id = $id; });
			$succeed = 1;
			last;
		}
		else {
			$mech->follow_link( text_regex => qr/contact/i );
			$emails = $biz->get_emails($mech->content);
			if (ref $emails && (scalar @{$emails} > 0)) {
				$turl = $mech->uri;
				$reason = 'find email in bbb ' . __FILE__ . '['. __LINE__ . ']';
				goto LOOP;
			}
			$mech->follow_link( text_regex => qr/about/i );
			if (ref $emails && (scalar @{$emails} > 0)) {
				$turl = $mech->uri;
				$reason = 'find email in ccc ' . __FILE__ . '['. __LINE__ . ']';
				goto LOOP;
			}
		}
	}
	unless ($succeed) {
		# At last, mark it processed.
		$sth = $dbh->do( q{ update } . UKCONTACTS . qq{ set accessible='N', reason='first loop not find email.', date = now() where id = $id; });
	}
}

$dbh->disconnect();

$end_time = time;
$biz->write_log( "Total days' data : [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$biz->write_log("----------------------------------------------\n");
$biz->close_log();

exit 8;
