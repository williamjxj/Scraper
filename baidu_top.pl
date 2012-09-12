#! /opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use XML::RSS::Parser::Lite;
use LWP::Simple;
use DBI;
use Getopt::Long;

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

my ($xml, $rank, $rp) = (undef);
$rp = new XML::RSS::Parser::Lite;

# while (($key, $val) = each(%{$bd->{'ranks'}}))
foreach $rank (@{$bd->{'ranks'}}) {
	$bd->{'url'} = $rank->[1];
	$h->{'category'} = $dbh->quote($rank->[2]);
	$h->{'cate_id'} = $bd->select_category($rank->[2]);
	$h->{'item'} = $dbh->quote($rank->[0]);
	$h->{'item_id'} = $bd->select_item($rank, $h);

	$xml = get($bd->{'url'});
	if(!defined($xml) || $xml eq '') {
		$bd->write_log('Fail!'.$bd->{'url'}.', '.$h->{'item_id'}.', '.$h->{'cate_id'});
		next;
	}

	$num ++;
	
	# $title, $link, $pubDate, $source, $author, $desc
	my $aref = $bd->get_item($xml);

	$h->{'title'} = $dbh->quote($aref->[0]); 
	$h->{'url'} = $dbh->quote($aref->[1]);
	$h->{'pubDate'} = $dbh->quote($aref->[2]);
	$h->{'author'} = $dbh->quote($aref->[3]);
	$h->{'source'} = $dbh->quote($bd->{'url'}.'->'.$aref->[4]); 
	$h->{'desc'} = $dbh->quote($aref->[5]);

	$bd->insert_baidu($h, $rank);
}
	
$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total total data: [ " . $num . "], " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;