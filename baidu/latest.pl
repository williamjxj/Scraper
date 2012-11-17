#! /usr/bin/perl -w
# http://bbs.chinaunix.net/thread-364569-1-1.html

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use LWP::Simple;
use DBI;
use Getopt::Long;
use Encode qw(encode decode);

use lib qw(../lib/);
use config;
use db;
use baidu;

BEGIN
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

our ( $bd, $log ) = ( undef, undef );

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
our $dbh = new db( $user, $pass, $dsn );

$bd = new baidu( $dbh );

$start_time = time;

$log = $bd->get_filename(__FILE__);
$bd->set_log($log);
$bd->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ($num1, $num2, $web) = (0, 0);
our @non_rss = ('star_chuanwen', 'star_gangtai', 'star_neidi', 'star_oumei', 'star_rihan');

# Never insert without the following info.
my $h = {
	'category' => '',
	'cate_id' => 0,
	'item' => '',
	'item_id' => 0,
	'createdby' => $dbh->quote($bd->get_os_stripname(__FILE__)),
};

GetOptions( 'log' => \$log, 'web=s' => \$web );

# for test purpose
if ($web) {
	my $html = get( $web );
	print Dumper( $html );
	exit 1;
}

my ($xml, $rd, $aref, $flg) = (undef, [], {}, 1);

foreach $rd (@{$bd->{'latest'}}) {
	$bd->{'url'} = $rd->[1];
	my ($channel) = ($bd->{'url'} =~ m/class=(.*?)&/);

	$xml = get($bd->{'url'});
	if(!defined($xml) || $xml eq '') {
		$bd->write_log('Fail!'.$bd->{'url'}.', '.$h->{'item_id'}.', '.$h->{'cate_id'});
		next;
	}

	$num1 ++;
	$num2 = 0;

	$h->{'category'} = $dbh->quote($rd->[2]);
	$h->{'cate_id'} = $bd->select_category($rd->[2]);
	$h->{'item'} = $dbh->quote($rd->[0]);
	$h->{'item_id'} = $bd->select_item($rd, $h);
	$h->{'author'} = $dbh->quote($channel);

	if ($channel && grep /$channel/, @non_rss) {
		$aref = $bd->get_non_rss($xml);
		$flg = 0;
	}
	else {
		$aref = $bd->get_item1($xml);	
		$flg = 1;
	}

	foreach my $rss (@$aref) {
		# $title, $link, $pubDate, $source, $author, $desc
		my ($t1, $t2, $t3, $t4, $t5, $t6) = @{$rss};

		$num2 ++;
	
		if( $flg ) {
			$t1 = decode("euc-cn", "$t1");
			$t4 = decode("euc-cn", "$t4");
			$t5 = decode("euc-cn", "$t5");
			$t6 = decode("euc-cn", "$t6");
		}
		else {
			$t3 = $bd->get_time('1') . ' ' . $t3;  # change 9:31 to '2012-09-14 9:31'
		}
	
		$h->{'title'} = $dbh->quote($t1); 
		$h->{'url'} = $dbh->quote($t2);
		$h->{'pubDate'} = $dbh->quote($t3);
	
		if ($t4) {
			$h->{'source'} = $dbh->quote($t5);
		}
		elsif ($t5) {
			$h->{'source'} = $dbh->quote($t5);
		}

		$h->{'desc'} = $dbh->quote($t6);
		$bd->insert_baidu($h, $rd);		

		# delete $h->{$_} for (keys %{$h});
	}
}
	
$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total total data: [ " . $num1 . ', ' . $num2 . " ], [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;
