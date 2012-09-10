#! /opt/lampp/bin/perl -w
# 1. 操作contents 表.
# 2. issue: 不是全部下载,而是每次更新,只下载更新部分!!

use lib qw(./lib/);
use config;
use db;
use food_120v_cn;

use warnings;
use strict;
use utf8;
#use DateTime;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;
#use feature qw(say);

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

#-----------------------------------
# 0. initialize:
#-----------------------------------

our ( $mech, $db, $news, $log ) = ( undef, undef );

#数据库句柄。
our ( $dbh, $sth );

our ( $page_url,  $next_page )   = ( 'http://food.120v.cn/FoodsTypeList.html', undef );

our ( $num,  $start_time, $end_time, $end_date ) = ( 0,     0,     0, '' );

our ($cate_id, $createdby) = (FOOD, '网页自动抓取程序');

my ($name, $item_id, $item_name, $notes, $published_date, $created, $content);

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

# 初始化页面抓取模块:
$news = new food_120v_cn( $db->{dbh} ) or die;

# 日志文件:
$start_time = time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . __FILE__ . "]: start at: [" . localtime() . "]." );
# print  qx(basename __FILE__) ;

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
	exit 1;
}
else {
	my $items= $news->select_items();
	print Dumper($items);
}

if ($keyword) {
	$news->select_keywords(utf8::encode($keyword));
}


########### 正式 抓取

$mech = WWW::Mechanize->new( autocheck => 0 );

my ($t) = (qx(basename $0  .pl) =~ m"(\w+)");
$t = q{'网页自动抓取程序'}  unless $t;
$createdby = $dbh->quote($t);

LOOP:
$mech->get($page_url);
$mech->success or die $mech->response->status_line;


# 页面的有效链接, 和翻页部分.
my $links = $news->get_links( $news->parse_list_page_1($mech->content));
$next_page = $news->get_next_page( $news->parse_list_page_2($mech->content));

if($next_page) {
	$page_url = $next_page;
}
else {
	$page_url = '';
}

$news->write_log($links);
$news->write_log($next_page, 'next page:'.__LINE__.":");

foreach my $url ( @{$links} ) {

	$mech->follow_link( url => $url );
	$mech->success or next;

	# print $mech->content;

	$num ++;
	
	( $name, $item_name, $notes, $published_date, $content ) = $news->parse_detail( $mech->content );

	$name = $dbh->quote($name);
	$notes = $dbh->quote($notes);
	$content = $dbh->quote($content);
	$item_name = $dbh->quote($item_name);
	$published_date = $dbh->quote($published_date);

	my $sql = qq{ insert ignore into contents
			(linkname,
			notes,
			content,
			cate_id,
			item,
			published_date, 
			createdby,
			created 
		) values(
			$name, 
			$notes,
			$content,
			$cate_id,
			$item_name,
			$published_date,
			$createdby,
			now()
		)};
	
	$sth = $dbh->do($sql);
	
	my $keywords = $news->get_keywords($news->parse_keywords_list($mech->content));
	#插入关键词
	foreach my $keyword (@{$keywords})  {
		$keyword = $dbh->quote($keyword);
		#$sql = qq{ insert ignore into tags(name) values( $keyword ) };
		#$sth = $dbh->do($sql);	
	
		$sql = qq{ insert ignore into keywords(keyword) values( $keyword ) };
		$sth = $dbh->do($sql);	
	}
	$mech->back();
}

$news->write_log( "There are total [ $num ] records was processed succesfully for $page_url, $item_name !\n");

goto LOOP if ($page_url);


# 2. 只插入item_name,没有item_id,所以,执行之后,还要:
# update contents c, (select iid,name from items) i set c.iid=i.iid where c.iid is NULL and c.item=i.name
$news->update_contents();

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
