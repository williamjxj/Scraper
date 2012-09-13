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

my ($num, $url, $html, $rss) = (0, BAIDU_RSS, '', '');

$html = get $url;
die "Couldn't get $url" unless defined $html;

$html =~ m {
	<div\sid="feeds">
	(.*?)
	<script
}sgix;
$rss = $1;

# 一大堆的解析,将html转化为纯内容的 '名字'->'链接地址' pair.
#$rss =~ s/(^|\n)[\n\s]*/$1/g;
#$rss =~ tr/\n//s;
$rss =~ s/^\s*\n+//mg; 

# 去掉html tags.
$rss =~ s/^\s*(<div>|<\/div>|<li>|<\/li>|<ul>|<\/ul>)\s*\n+//mg; 

# 去掉<span>前后缀.
$rss =~ s/<span(?:.*?)>//mg; 
$rss =~ s/<\/span>//mg; 

# 去掉<input tag,只是得到value=""中的值.
$rss =~ s/<input(?:.*?)value="//mg; 
$rss =~ s/">\s*$//mg; 

# 去掉 <ul><li> tag.
$rss =~ s/^\s*<\/ul>\s*<\/li>\s*\n+//mg; 
$rss =~ s/^\s*<\/li>\s*<li>\s*\n+//mg; 

# 去掉 剩余的不需要的 tag.
$rss =~ s/^\s*<strong>.*$//mg;
$rss =~ s/^\s*<sup>.*$//mg;
$rss =~ s/^\s*<ul.*\n+//mg;
$rss =~ s/^\s*<div.*\n+//mg;

# 去掉 只包含 tag的行.
$rss =~ s/^\s*(<\/li>|<li|<ul|<\/ul>|<div|<\/div>).*\n+//mg; 

# 关键: 将两行合并成一行: 对于^M 结尾的行， 去掉^M回车换行, 合并两行成一行。
$rss =~ s/\s+\n+//mg;

# 前移，去掉前导空格。
$rss =~ s/^\s+//mg;

my ($name, $link, $sql) = ('','','');
while($rss =~ m/([^\s]*?)\s+([^\s]*?)$/mg) {
	print '['. $1 . "]: [" . $2 . "];\n";
	$name = $dbh->quote($1);
	$link = $dbh->quote($2);
	$sql = qq{ insert ignore into baidu_rss(
		name,
		url,
		dt) 
	values(
		$name,
		$link,
		now()
	)};
	$bd->write_log($sql);
	$dbh->do($sql);	
}


$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->close_log();

exit 8;
