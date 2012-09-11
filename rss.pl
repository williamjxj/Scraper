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

my $h = {};

$h->{'category'} = '\'\'';
$h->{'cate_id'} = 0;
$h->{'item'} = '\'\'';
$h->{'item_id'} = 0;

my $f1 = __FILE__;
my ($f) = (qx(basename $f1 .pl) =~ m"(\w+)");
$h->{'createdby'} = $dbh->quote($f);


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

my ($key, $val) = ('','');
my $rp = new XML::RSS::Parser::Lite;
while (($key, $val) = each(%{$bd->{'ranks'}})) {
	# print $val.', ', $key."<br/>\n";
	my $xml = get($val);
	
	# $rp->parse($xml);

	# $title, $link, $pubDate, $source, $author, $desc
	my $aref = $bd->get_item($xml);

	$h->{'title'} = $dbh->quote($aref->[0]); 
	$h->{'url'} = $dbh->quote($aref->[1]);
	$h->{'pubDate'} = $dbh->quote($aref->[2]);
	$h->{'source'} = $dbh->quote($aref->[3]); 
	$h->{'author'} = $dbh->quote($aref->[4]);
	$h->{'desc'} = $dbh->quote($aref->[5]);

	$bd->insert_baidu($h);
}
	
$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;

