#! /opt/lampp/bin/perl -w
# http://bbs.chinaunix.net/thread-364569-1-1.html

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use XML::RSS::Parser::Lite;
use LWP::Simple;
use DBI;
use Getopt::Long;
use Encode qw(encode decode);

use lib qw(./lib/);
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
	$ENV{'PATH'} = '/usr/bin/:/bin/:.';
	local ($|) = 1;
	undef $/;
}


our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

our ( $db, $dbh ) = ( undef, undef );

our ( $bd, $log ) = ( undef, undef );

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$bd = new baidu( $db->{dbh} );

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
	'createdby' => $dbh->quote($bd->get_createdby(__FILE__)),
};

GetOptions( 'log' => \$log );

my ($xml, $rd, $rp) = (undef);
$rp = new XML::RSS::Parser::Lite;

foreach $rd (@{$bd->{'latest'}}) {
	$bd->{'url'} = $rd->[1];
	$h->{'category'} = $dbh->quote($rd->[2]);
	$h->{'cate_id'} = $bd->select_category($rd->[2]);
	$h->{'item'} = $dbh->quote($rd->[0]);
	$h->{'item_id'} = $bd->select_item($rd, $h);

	$xml = get($bd->{'url'});
	if(!defined($xml) || $xml eq '') {
		$bd->write_log('Fail!'.$bd->{'url'}.', '.$h->{'item_id'}.', '.$h->{'cate_id'});
		next;
	}

	$num ++;

	# $title, $link, $pubDate, $source, $author, $desc
	my $aref = $bd->get_item($xml);
	my ($t1, $t2, $t3, $t4, $t5, $t6) = @{$aref};

	$t1 = decode("euc-cn", "$t1");
	$t4 = decode("euc-cn", "$t4");
	$t5 = decode("euc-cn", "$t5");
	$t6 = decode("euc-cn", "$t6");

	$h->{'title'} = $dbh->quote($t1); 
	$h->{'url'} = $dbh->quote($t2);
	$h->{'pubDate'} = $dbh->quote($t3);
	$h->{'source'} = $dbh->quote($bd->{'url'}.'->'.$t4);
	$h->{'author'} = $dbh->quote($t5);
	$h->{'desc'} = $dbh->quote($t6);

	$bd->insert_baidu($h, $rd);
}
	
$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total total data: [ " . $num . "], " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;