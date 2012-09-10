package baidu;

use config;
use common;
@ISA = qw(common);
use strict;
our ( $sth );

use constant CONTACTS => q{contexts};

#http://top.baidu.com/rss.php
our $ranks = {
	'实时热点排行榜' => 'http://top.baidu.com/rss_xml.php?p=top10',
	'七日关注排行榜' => 'http://top.baidu.com/rss_xml.php?p=weekhotspot',
	'今日热门搜索排行榜' => 'http://top.baidu.com/rss_xml.php?p=top_keyword',
	'世说新词排行榜' => 'http://top.baidu.com/rss_xml.php?p=shishuoxinci',
	'最近事件排行榜' => 'http://top.baidu.com/rss_xml.php?p=shijian',
	'上周事件排行榜' => 'http://top.baidu.com/rss_xml.php?p=shijian_lastweek',
	'上月事件排行榜' => 'http://top.baidu.com/rss_xml.php?p=shijian_lastmonth',
	'今日热点人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=hotman',
	'今日美女排行榜' => 'http://top.baidu.com/rss_xml.php?p=girls',
	'今日帅哥排行榜' => 'http://top.baidu.com/rss_xml.php?p=boys',
	'今日女演员排行榜' => 'http://top.baidu.com/rss_xml.php?p=FStar',
	'今日男演员排行榜' => 'http://top.baidu.com/rss_xml.php?p=MStar',
	'今日女歌手排行榜' => 'http://top.baidu.com/rss_xml.php?p=ygeshou',
	'今日男歌手排行榜' => 'http://top.baidu.com/rss_xml.php?p=ngeshou',
	'今日体坛人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=titan',
	'今日互联网人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=internet',
	'今日名家人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=mingjia',
	'今日财经人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=caijing',
	'今日富豪排行榜' => 'http://top.baidu.com/rss_xml.php?p=rich',
	'今日政坛人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=zhengtan',
	'今日历史人物排行榜' => 'http://top.baidu.com/rss_xml.php?p=lishiren',
	'今日人物关系排行榜' => 'http://top.baidu.com/rss_xml.php?p=relation',
	'今日慈善组织排行榜' => 'http://top.baidu.com/rss_xml.php?p=cishan',
	'今日房产企业排行榜' =>'http://top.baidu.com/rss_xml.php?p=fangchanqy',
};


sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'baidu_rss';
	$self->{ranks} = $ranks;
	bless $self, $type;
}

1;
