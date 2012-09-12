#! /opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;
use Encode;

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

our ( $mech, $db, $news, $log ) = ( undef, undef );

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

# for test purpose
if ($web) {
	$mech->get( $web );
	$mech->success or die $mech->response->status_line;
	exit 1;
}

$mech = WWW::Mechanize->new( autocheck => 0 );

my ($xml, $rd, $category, $url) = (undef);


foreach $rd (@{$bd->{'focus'}}) {
	$url = $rd->[1];
	$category = $rd->[2];

	$h->{'cate_id'} = $bd->select_category($category);
	$h->{'item_id'} = $bd->select_item($rd, $h->{'cate_id'}, $h->{'createdby'});
	$h->{'category'} = $dbh->quote($category);
	$h->{'item'} = $dbh->quote($rd->[0]);

	$mech->get($url);
	$mech->success or die $mech->response->status_line;

	$xml = $mech->content;
	
	# $title, $link, $pubDate, $source, $author, $desc
	my $aref = $bd->get_item($xml);

	$h->{'title'} = encode("utf-8", $aref->[0], Encode::FB_CROAK); 

	# if (is_utf8($h->{'title'}, Encode::FB_CROAK)) { print "UTF-8\n"; }

	# $h->{'title'} = encode_utf8(decode("gb2312", $aref->[0]));
	# $h->{'title'} = $dbh->quote($aref->[0]); 
	$h->{'title'} = $dbh->quote($h->{'title'}); 
	$h->{'url'} = $dbh->quote($aref->[1]);
	$h->{'pubDate'} = $dbh->quote($aref->[2]);
	$h->{'source'} = $dbh->quote($aref->[3]); 
	$h->{'author'} = $dbh->quote($aref->[4]);
	$h->{'desc'} = $dbh->quote($aref->[5]);

	$bd->insert_baidu($h, $rd);

}

$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->close_log();

exit 8;

