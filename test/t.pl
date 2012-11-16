#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Encode;
use Text::Iconv;
use DBI;

use lib qw(./lib/);
use config;
use db;
use baidu;

my %attrs = (AutoCommit => 1);
my $dsn = "DBI:mysql:host=localhost;database=dixi";
my $dbh = DBI->connect($dsn, "dixitruth", "dixi123456", \%attrs) or die "Can't connect to MySQL server\n";

#my $tt =  '<title><![CDATA[兰州计划斥资近50亿 把南部地区天然森林引入城]]></title>';
my $tt =  '兰州计划斥资近50亿 把南部地区天然森林引入城';
#Encode::from_to($tt, "gb2312", "utf8");
#print $tt;

my $bd = new baidu( $dbh );

my $h = {};
#$h->{'createdby'} = encode("gb2312", decode("utf-8", '百度'));
$h->{'createdby'} = $dbh->quote('百度');
my $category = '新闻';
# $category = encode("utf-8", decode("gb2312", $category));  # 新闻

#$category = Encode::from_to($category, "gb2312", "utf8");
my $rank = {}; #{'新闻2' , 'http://news.baidu.com', '新闻1'};
$h->{'cate_id'} = $bd->select_category($category);
$h->{'item_id'} = $bd->select_item($rank, $h->{'cate_id'}, $h->{'createdby'});
$h->{'category'} = $dbh->quote($category);
$h->{'item'} = $dbh->quote($rank->[0]);

$h->{'cate_id'} = $bd->select_category($category);
$h->{'item_id'} = $bd->select_item($rank, $h->{'cate_id'}, $h->{'createdby'});
$h->{'category'} = $dbh->quote($category);
$h->{'item'} = $dbh->quote($rank->[0]);

my $sql = qq{ insert ignore into t_baidu (
	title,
	url,
	pubDate,
	source, 
	author, 
	content,
	category,
	cate_id,
	item,
	item_id,
	createdby,
	created
) values(
	$h->{'title'}, 
	$h->{'url'},
	$h->{'pubDate'},
	$h->{'source'}, 
	$h->{'author'},
	$h->{'desc'},
	$h->{'category'},
	$h->{'cate_id'},
	$h->{'item'},
	$h->{'item_id'},
	$h->{'createdby'},
	now()
)
on duplicate key update content = $h->{'desc'}, pubDate = $h->{'pubDate'}
};

$dbh->do($sql);

$dbh->disconnect();

exit;
