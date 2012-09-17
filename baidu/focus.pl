#! /opt/lampp/bin/perl -w
#use utf8;
#use encoding 'utf8';

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use LWP::Simple;
use DBI;
use Getopt::Long;
use Encode qw(from_to encode decode);

use lib qw(../lib/);
use config;
use db;
use baidu;

sub BEGIN
{
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	$ENV{'HOME'} = '/home/williamjxj/scraper/';
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

my ($num) = (0);

# Never insert without the following info.
my $h = {
	'category' => '',
	'cate_id' => 0,
	'item' => '',
	'item_id' => 0,
	'createdby' => $dbh->quote('baidu_' . $bd->get_os_stripname(__FILE__)),
};

GetOptions( 'log' => \$log );

my ($xml, $rd) = (undef);
foreach $rd (@{$bd->{'focus'}}) {
	$bd->{'url'} = $rd->[1];
	my ($channel) = ($bd->{'url'} =~ m/class=(.*?)&/);

	$xml = get($bd->{'url'});
	if(!defined($xml) || $xml eq '') {
		$bd->write_log('Fail!'.$bd->{'url'}.', '.$h->{'item_id'}.', '.$h->{'cate_id'});
		next;
	}

	$num ++;

	$h->{'category'} = $dbh->quote($rd->[2]);
	$h->{'cate_id'} = $bd->select_category($rd->[2]);
	$h->{'item'} = $dbh->quote($rd->[0]);
	$h->{'item_id'} = $bd->select_item($rd, $h);
	$h->{'author'} = $dbh->quote($channel);

	# $title, $link, $pubDate, $source, $author, $desc
	my $aref = $bd->get_item($xml);
	
	foreach my $rss (@$aref) {
	
		my ($t1, $t2, $t3, $t4, $t5, $t6) = @{$rss};
	
		$t1 = decode("euc-cn", "$t1");
		$t4 = decode("euc-cn", "$t4");
		$t5 = decode("euc-cn", "$t5");
		$t6 = decode("euc-cn", "$t6");
	
		# $h->{'title'} = encode("utf-8", decode("gb2312", $aref->[0])); 
		# if (is_utf8($h->{'title'}, Encode::FB_CROAK)) { print "UTF-8\n"; }
		# $h->{'title'} = encode_utf8(decode("gb2312", $aref->[0]));
		# $t3 = from_to($t3, 'gb2312', 'utf8');
		# $h->{'source'} = $dbh->quote($aref->[3]); 
		# $h->{'author'} = $dbh->quote($aref->[4]);
	
		$h->{'title'} = $dbh->quote($t1); 
		$h->{'url'} = $dbh->quote($t2);
		$h->{'pubDate'} = $dbh->quote($t3);
		$h->{'desc'} = $dbh->quote($t6);

		if ($t4) {
			$h->{'source'} = $dbh->quote($t4);
		} 
		elsif($t5)  {
			$h->{'source'} = $dbh->quote($t5);
		}

		$bd->insert_baidu($h, $rd);
	}
}

$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total total data: [ " . $num . "], " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;
