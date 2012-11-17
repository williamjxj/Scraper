#! /usr/bin/perl -w
# http://top.baidu.com/
# windows下无法安装,用 LWP::Simple替代.
#use XML::RSS::Parser::Lite;

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use LWP::Simple;
use DBI;
use Getopt::Long;

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
	#undef $/;
}

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

our ( $bd, $log ) = ( undef, undef );

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";

our $dbh = new db( $user, $pass, $dsn );

$bd = new baidu($dbh);

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
	'createdby' => $dbh->quote($bd->get_os_stripname(__FILE__)),
};

GetOptions( 'log' => \$log );

my ($xml, $rank, $data) = (undef);

# while (($key, $val) = each(%{$bd->{'ranks'}}))
foreach $data (<DATA>) {
	@{$rank} = split(/,/, $data);
	chomp $rank->[2];
	$bd->{'url'} = $rank->[1];
	# 'http://top.baidu.com/buzz.php?p=top10'
	# my ($channel) = ($bd->{'url'} =~ m/class=(.*?)&/);
	my $channel = $bd->{'url'};
	
	$h->{'cate_id'} = $bd->select_category($rank->[2]);
	$h->{'category'} = $dbh->quote($rank->[2]);
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
	my $r = $aref->[0];

	$h->{'title'} = $dbh->quote($r->[0]); 
	$h->{'url'} = $dbh->quote($r->[1]);
	if($r->[2]) {
		$h->{'pubDate'} = $dbh->quote($r->[2]);
	}
	else {
	    $h->{'pubDate'} = $dbh->quote($bd->get_time('2'));
	}
	$h->{'author'} = $dbh->quote($channel);
	$h->{'desc'} = $dbh->quote($r->[5]);

	# $r->[3] = $r->[4]
	if($r->[3]) {
		$h->{'source'} = $dbh->quote($r->[3]);
	}
	elsif($r->[4]) {
		$h->{'source'} = $dbh->quote($r->[4]);		
	} 

	$bd->insert_baidu($h, $rank);
	
	#william add on 2012-11-16
	insert_keyword_kr($dbh, $h->{'desc'});
}
	
$dbh->disconnect();
$end_time = time;
$bd->write_log( "Total total data: [ " . $num . "], " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$bd->write_log("----------------------------------------------\n");
$bd->close_log();

exit 8;

sub insert_keyword_kr 
{
	my ($dbh, $html) = @_;
	my $aoh = [];

	while ($html =~ m {
		</th>
		.*?
		<td>
		.*?
		href=(.*?)  #1. kurl
		>
		(.*?)   #2. keyword
		</a>
	    }sgix) {
		my ( $t1, $t2 ) = ( $1, $2 );
		$t1 =~ s/^.*?"//;
		$t1 =~ s/\\.*$//;
		push( @{$aoh}, [ $t1, $t2 ] );
	};
	
	my ($kurl, $keyword, $kid, $sth, $q);
	foreach my $k ( @{$aoh} ) {
		$kurl = $k->[0];
		$keyword = $k->[1];
		
		$sth = $dbh->prepare("INSERT IGNORE INTO keywords(keyword, createdby, created) VALUES ( ?, 'top', now() )");
		$sth->execute($keyword) or next;
	
		$kid = $dbh->{'mysql_insertid'} or $kid = $bd->get_kid_by_keyword($keyword);
	
		$sth = $dbh->prepare(
			"INSERT IGNORE INTO key_related (rk, kurl, kid, keyword, createdby, created) 
			VALUES(?,?,?,?,'top',now())"
		);
		$sth->execute( $keyword, $kurl, $kid, $keyword);
	}
}

__DATA__
实时热点排行榜,http://top.baidu.com/rss_xml.php?p=top10,新闻
七日关注排行榜,http://top.baidu.com/rss_xml.php?p=weekhotspot,新闻
今日热门搜索排行榜,http://top.baidu.com/rss_xml.php?p=top_keyword,新闻
世说新词排行榜,http://top.baidu.com/rss_xml.php?p=shishuoxinci,新闻
最近事件排行榜,http://top.baidu.com/rss_xml.php?p=shijian,事件
上周事件排行榜,http://top.baidu.com/rss_xml.php?p=shijian_lastweek,事件
上月事件排行榜,http://top.baidu.com/rss_xml.php?p=shijian_lastmonth,事件
今日热点人物排行榜,http://top.baidu.com/rss_xml.php?p=hotman,人物
今日美女排行榜,http://top.baidu.com/rss_xml.php?p=girls,人物
今日帅哥排行榜,http://top.baidu.com/rss_xml.php?p=boys,人物
今日女演员排行榜,http://top.baidu.com/rss_xml.php?p=FStar,明星
今日男演员排行榜,http://top.baidu.com/rss_xml.php?p=MStar,明星
今日女歌手排行榜,http://top.baidu.com/rss_xml.php?p=ygeshou,明星
今日男歌手排行榜,http://top.baidu.com/rss_xml.php?p=ngeshou,明星
今日体坛人物排行榜,http://top.baidu.com/rss_xml.php?p=titan,明星
今日互联网人物排行榜,http://top.baidu.com/rss_xml.php?p=internet,明星
今日名家人物排行榜,http://top.baidu.com/rss_xml.php?p=mingjia,明星
今日财经人物排行榜,http://top.baidu.com/rss_xml.php?p=caijing,明星
今日富豪排行榜,http://top.baidu.com/rss_xml.php?p=rich,人物
今日政坛人物排行榜,http://top.baidu.com/rss_xml.php?p=zhengtan,人物
今日历史人物排行榜,http://top.baidu.com/rss_xml.php?p=lishiren,人物
今日人物关系排行榜,http://top.baidu.com/rss_xml.php?p=relation,人物
今日慈善组织排行榜,http://top.baidu.com/rss_xml.php?p=cishan,公益
今日房产企业排行榜,http://top.baidu.com/rss_xml.php?p=fangchanqy,房地产
