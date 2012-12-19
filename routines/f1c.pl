#! /usr/bin/perl -w
# 1. 操作contents 表.
# 2. issue: 不是全部下载,而是每次更新,只下载更新部分!!
#use DateTime;
#use constant CATEGORY => q/食品/;

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;
use feature qw(say);
use constant START_URL => q{http://food.120v.cn/FoodsTypeList.html};
use constant ROOT_URL => q{http://food.120v.cn/};

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use food_120v_cn;

BEGIN
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

#-----------------------------------
# 0. initialize:
#-----------------------------------
our ( $mech, $sth, $news, $log ) = ( undef, undef );

our ( $page_url,  $next_page )   = ( START_URL, undef );

our ( $num,  $start_time, $end_time, $end_date ) = ( 0,     0,     0, '' );

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";

#数据库句柄。
our $dbh = new db( $user, $pass, $dsn );

# 初始化页面抓取模块:
$news = new food_120v_cn( $dbh ) or die;

# 日志文件:
$start_time = time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . __FILE__ . "]: start at: [" . localtime() . "]." );

my $h = {
	'category' => $dbh->quote(FOOD),
	'cate_id' => 3,
	'item' => '\'\'',
	'item_id' => 0,
	'createdby' => $dbh->quote($news->get_os_stripname(__FILE__)),
};

##### 判别输入粗参数部分:
my ( $item, $keyword, $help ) = ( undef, undef, undef );
usage()
  unless (
	GetOptions(
		'item=s'     => \$item,
		'keyword=s' => \$keyword,
		'help|?'     => \$help
	)
  );
  
$help && usage();

# 判断是否有输入参数?
if($item) {
	print Dumper($news->select_item_by_id($item));
	#$dbh->show_results($sql);
	exit 1;
}
=comment
else {
	my $items= $news->select_items();
	$news->write_log($items);
}
=cut
if ($keyword) {
	$news->select_keywords(utf8::encode($keyword));
}

########### 正式 抓取 ###########
$mech = WWW::Mechanize->new( autocheck => 0 );
$mech->timeout( 30 );

# 从START_URL: 'http://food.120v.cn/FoodsTypeList.html'开始:
LOOP:
$mech->get($page_url);
$mech->success or die $mech->response->status_line;


# 页面的有效链接, 和翻页部分.
my $links = $news->get_links( $news->parse_list_page_1($mech->content));
$next_page = $news->get_next_page( $news->parse_list_page_2($mech->content));

if($next_page) {
	$page_url = $next_page;
	$page_url = '' if ($page_url =~ m/page=4/);
}
else {
	$page_url = '';
}

#$news->write_log($links);
$news->write_log($next_page, 'next page:'.__LINE__.":");

$h->{'cate_id'} = $news->select_category();

foreach my $url ( @{$links} ) {

	$mech->follow_link( url => $url );
	if(! $mech->success) {
		$news->write_log('Fail : ' . $page_url . ', [' . $h->{'item_id'} . '], ' . $url);
		next;
	}
	$num ++;
	
	#( $name, $item_name, $notes, $published_date, $content ) = $news->parse_detail( $mech->content );
	my ($t1, $t2, $t3, $t4, $t5) = $news->parse_detail( $mech->content );
	
	$h->{'title'} = $dbh->quote($t1);
	$h->{'item'} = $dbh->quote($t2);
	$h->{'item_id'} = $news->select_item_by_name($t2);
	$h->{'pubdate'} = $dbh->quote($t4);
	$h->{'content'} = $dbh->quote($t5);

	$h->{'url'} = $dbh->quote(ROOT_URL.$url);
	$h->{'source'} = $dbh->quote($url);
	$h->{'author'} = $dbh->quote($t3);

	$h->{'clicks'} = $news->generate_random();
	$h->{'likes'} = $news->generate_random(100);
	$h->{'guanzhu'} = $news->generate_random(100);
		
	my $sql = qq{ insert ignore into contents
		(title,
		url,
		pubdate,
		author, 
		source,
		category,
		cate_id,
		item,
		iid,
		clicks,
		likes,
		guanzhu,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubdate'},
		$h->{'source'}, 
		$h->{'author'},
		$h->{'category'},
		$h->{'cate_id'},
		$h->{'item'},
		$h->{'item_id'},
		$h->{'clicks'},
		$h->{'likes'},
		$h->{'guanzhu'},
		$h->{'createdby'},
		now(),
		$h->{'content'}
	)};

	$sth = $dbh->do($sql);
	
	my ($kid, $q);
	my $keywords = $news->get_keywords($news->parse_keywords_list($mech->content));
	#插入关键词
	foreach my $keyword (@{$keywords})  {
		$q = $dbh->quote($keyword);
	
		$sql = qq{ insert ignore into keywords(keyword, createdby, created) values( $q, 'f1c', now() ) };
		$sth = $dbh->do($sql) or next;

		$kid = $dbh->{'mysql_insertid'};
		if(! $kid) {
			$kid=$news->get_kid_by_keyword($keyword);
		}

		$sql = qq{ insert ignore into key_related(rk, kurl, kid, keyword, createdby, created) 
			values( $q, '', $kid, $q, 'f1c', now() ) };
		$sth = $dbh->do($sql);	
	}
	$mech->back();
}

$news->write_log( "There are total [ $num ] records was processed succesfully for $page_url, $h->{'item'} !\n");

goto LOOP if ($page_url);


# 2. 只插入item_name,没有item_id,所以,执行之后,还要:
# update contents c, (select iid,name from items) i set c.iid=i.iid where c.iid is NULL and c.item=i.name
# $news->update_contents();

$dbh->disconnect();

$end_time = time;
$news->write_log( "Total [$num]: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$news->write_log("----------------------------------------------\n");
$news->close_log();

exit 8;


###### 帮助函数 #######

sub usage {
	print <<HELP;
Uage:
      $0
     or:
      $0 -n channel_name #new channel
     or:
      $0 -t 3
     or:
      $0 -k keyword
     or:
      $0 -h  [-v]
Description:
  -n which channel to scrape?
  -t from what date to download? default it's from 2 days before.
  -k keyword search
  -h this help
  -v version

Examples:
     (1) $0     # use default
     (3) $0 -n 'hot'       # scrape vancouver's gigs
     (4) $0 -n 'fagui'
     (5) $0 -h  # get help
     (6) $0 -v  # get version

HELP
	exit 3;	
}
