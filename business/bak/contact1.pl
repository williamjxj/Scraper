#!/usr/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe
## if (grep{ $_ =~ m#$turl#i } @deposits) 

use lib qw(../lib/);
use business_config;
use db;
use business;

use warnings;
use strict;
use Data::Dumper;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

local ($|) = 1;
undef $/;

our ( $num, $start_time, $end_time ) = ( 0, 0, 0 );
our ( $mech, $db, $biz, $log ) = ( undef, undef );
our ( $dbh, $sth );

$start_time = time;

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$biz = new business( $db->{dbh} );

$log = $biz->get_filename(__FILE__);
$biz->set_log($log);
$biz->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $help, $version, $succeed ) = ( undef, undef, 0 );

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout(10);

my $webs = $biz->select_category();

my ( $url, $email, $email1, $phone, $fax, $content );

foreach my $ary ( @{$webs} ) {

	my $url = $ary->[0];
	my $id   = $ary->[1];
	$url = 'http://' . $url if ($url !~ m/^http/);

	print "---------------------------------------------\n";
	print $url . "\n";

	$succeed = 0;

	$mech->get( $url );
	if (! $mech->success ) {
		my $reason = $dbh->quote( $mech->response->status_line );
		$sth = $dbh->do( qq{ update } . CONTACT . qq{ set accessible = 'N', content=$reason,  date = now() where id = $id; });
		print $mech->response->status_line;
		next;
	}
	my $html = $mech->content;

	my $emails = $biz->get_emails($html);
	if (scalar @{$emails} ge 1) {

		if ( defined $emails->[0] && $emails->[0] ) {
			$email = $emails->[0];
		}
		else {
			$email = '';
			$biz->write_log( "[" . $url . "] no email: [" . $emails . "]." );
		}
		if (defined $emails->[1] && $emails->[1]) {
			$email1 = $emails->[1];
		}
		else {
			$email1 = '';
		}

		# phone = '$phone', fax = '$fax' content = '$content',
		$sth = $dbh->do(
			qq{ update } . CONTACT . qq{ set
			email = '$email', email1 = '$email1', date = now() where id = $id;
		});
		$succeed = 1;
		next;
	}

	if ($html =~ m/\<frameset/i) {
		$sth = $dbh->do( qq{ update } . CONTACT . qq{ set accessible = 'N', content='frameset',  date = now() where id = $id; });
	}

	my $aoa =  $biz->get_hrefs($html);
	$aoa =  $biz->uniq($aoa);
	print Dumper($aoa);

	foreach my $turl ( @{$aoa} ) {
		next if $turl eq '/';

		$mech->follow_link( url => $turl );
		$mech->success or next;  # $mech->success or die $mech->response->status_line;

		my $emails = $biz->get_emails($mech->content);
		if (scalar @{$emails} ge 1) {
			if ( defined $emails->[0] && $emails->[0] ) {
				$email = $emails->[0];
			}
			else {
				$email = '';
				$biz->write_log( "[" . $turl . "] no email: [" . $emails . "]." );
			}
			if (defined $emails->[1] && $emails->[1]) {
				$email1 = $emails->[1];
				$email1 = '' if ($email1 eq $email);
			}
			else {
				$email1 = '';
			}
			$sth = $dbh->do(
				qq{ update } . CONTACT . qq{ set
				email = '$email', email1 = '$email1', date = now() where id = $id;
			});
			$succeed = 1;
			last;
		}
		else {
			$mech->back();
		}
	}
	unless ($succeed) {
		# At last, mark it processed.
		$sth = $dbh->do( qq{ update } . CONTACT . qq{ set email = '', content='first loop do not find email.', date = now() where id = $id; });
	}
}

$dbh->disconnect();

$end_time = time;
$biz->write_log( "Total days' data : [ "
	  . ( $end_time - $start_time )
	  . " ] seconds used.\n" );
$biz->write_log(
	"There are total [ $num ] records was processed succesfully!\n"
);
$biz->write_log("----------------------------------------------\n");
$biz->close_log();

exit 8;
