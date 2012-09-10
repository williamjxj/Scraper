#! /opt/lampp/bin/perl -w

use warnings;
use strict;
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

our ( $bd, $dbh, $sth ) = ( undef, undef, undef );

our ( $db, $news, $log ) = ( undef, undef );

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$bd = new baidu( $db->{dbh} );

$start_time = time;

$log = $bd->get_filename(__FILE__);
$bd->set_log($log);
$bd->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );


our ($all, $debug, $keyword, $web);
GetOptions(
		'all=s' => \$all,
		'debug' => \$debug,
		'keyword=s' => \$keyword,
		'log' => \$log,
		'web' => \$web,
	 );

if ($debug) {
	$bd->{web_flag} = '1';
}

my ($key, $val);
my $rp = new XML::RSS::Parser::Lite;
while (($key, $val) = each(%{$bd->{'ranks'}})) {
	# print $val.', ', $key."<br/>\n";
	my $xml = get($val);
	
	# $rp->parse($xml);
	
	my $ary = $bd->get_item($xml);
	print Dumper($ary);
	exit;
}

$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;

