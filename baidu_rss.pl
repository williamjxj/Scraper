#! /opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use LWP::Simple;
use DBI;
use Getopt::Long;
use Encode;

use lib qw(./lib/);
use config;
use db;
use common;

use constant BAIDU_RSS => 'http://www.baidu.com/search/rss.html';

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

our ( $log, $sth ) = ( undef, undef );

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";

our ($dbh, $bd);
$dbh = new db( $user, $pass, $dsn );
$bd = new common();

GetOptions( 'log' => \$log );

$log = $bd->get_filename(__FILE__) unless $log;
$bd->set_log($log);
$bd->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ($num, $url, $html, $aref, $rss) = (0, BAIDU_RSS, '', []);

$html = get $url;
die "Couldn't get $url" unless defined $html;

$html =~ m {
	<div\sid="feeds">
	(.*?)
	<script
}sgix;
$rss = $1;

#$rss =~ s/(^|\n)[\n\s]*/$1/g;
#$rss =~ tr/\n//s;
$rss =~ s/^\s*\n+//mg; 

$rss =~ s/^\s*(<div>|<\/div>|<li>|<\/li>|<ul>|<\/ul>)\s*\n+//mg; 

$rss =~ s/<span(?:.*?)>//mg; 
$rss =~ s/<\/span>//mg; 

$rss =~ s/<input(?:.*?)value="//mg; 
$rss =~ s/">\s*$//mg; 

print $rss;
exit;



$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->close_log();

exit 8;
