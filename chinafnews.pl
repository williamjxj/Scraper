#! /opt/lampp/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe -w
# 1. 操作contents 表.
# 2. issue: 不是全部下载,而是每次更新,只下载更新部分!!
# 3. in cygwin, use $ perl -d $0, TMD:终端显示有问题,没有办法debug.

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use lib qw(./lib/);
use config;
use db;
use chinafnews;

use constant BASEURL=>q{http://www.chinafnews.com/news/};

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
our ( $mech, $news, $log ) = ( undef, undef );

#数据库句柄.
our ( $db, $dbh ) = ( undef, undef );

#当前页, 翻页变量.
my ( $page_url,  $next_page, $current_page ) = ( undef, undef, undef );

# 记录数,开始,结束时间.
my ( $num, $total, $start_time, $end_time, $end_date ) = ( 0, 0, 0, 0, undef );

# 该程序归类:食品, 通道的id,名称 (under '食品'),和创建日期.
# 存放所有要插入数据库的标量。
my ($queue) = ([]);

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

# 初始化页面抓取模块:
$news = new chinafnews( $db->{dbh} ) or die;

# 日志文件:
$start_time = time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . __FILE__ . "]: start at: [" . localtime() . "]." );

# '网页自动抓取程序'加上引号,用于数据库的插入. 也可以直接定义为常量:
# use constant createdby=>q{'网页自动抓取程序'};
#$h->{'createdby'} = $dbh->quote('网页自动抓取程序');

my $h = {
	'category' => $dbh->quote(FOOD),
	'cate_id' => 3,
	'item' => '',
	'item_id' => 0,
	'createdby' => $dbh->quote($news->get_createdby(__FILE__)),
};

##### 判别输入粗参数部分:
my ($edate, $item, $keywords, $help, $version) = (undef, undef, undef, undef, undef);
my ($aurl, $file) = (undef, undef);

usage()
  unless (
	GetOptions(
		'aurl=s'	=> \$aurl,
		'file=s'	=> \$file,
		'edate=s'   => \$edate,
		'item=s'  => \$item,
		'keywords=s' => \$keywords,
		'help|?'     => \$help,
		'version'    => \$version
	)
  );
  
$help && usage();

# 判断是否有输入参数?
# date +'%a %d %b' -d "2 day ago"
if ($edate) {
	$end_date = $news->get_end_date($edate);
}
else {
	$edate =  INTERVAL_DATE;	
}

if($item) {
	push(@{$queue}, $news->select_item_by_id($item));
	print Dumper($queue);
	exit;
}
else {
	$queue= $news->select_items();
}

if ($keywords) {
	my $kws = $news->select_keywords(utf8::encode($keywords));
	print Dumper($kws);
	exit;
}
if ($version) {
	print VERSION;
	exit;
}

########### 正式 抓取

$mech = WWW::Mechanize->new( autocheck => 0 );

#用于测试，如果哪个网页出错，可以直接定位，来查找原因。
if ($aurl) {
	print $aurl."\n";
	$mech->get($aurl);
	$mech->success or die $mech->response->status_line;
	#print($mech->content);
	my ( $name, $url, $pubdate, $content ) = $news->parse_detail( $mech->content );
	if($name eq '') {
		( $name, $pubdate, $content ) = $news->parse_detail_without_from( $mech->content );
	}
	print $name . "\n";
	print $url . "\n";
	print $pubdate . "\n";
	print $content . "\n";
	exit 10;
}

# 对于上次处理失败的case,再次处理一遍。
if ($file) {
	open FILE, "< ./logs/again.txt" or die $!;
	my (@ary, $id, $url);
	while (<FILE>) {
		chomp;
		($id, $url) = ($_ =~ m /(.*),(.*)/);
		push(@ary, [$id, $url]);
	}
	close(FILE);
	$queue = \@ary;
}

# 第一次从首页开始抓取,以后取'下一页'的链接,继续抓取.
foreach my $li (@{$queue}) {
	$h->{'item_id'} = $li->[0];
	$h->{'item'} = $dbh->quote($li->[1]);
	$page_url = BASEURL . $li->[2];
	$num = 0; #将循环计数复位.
	$news->write_log([$h->{'item_id'}, $h->{'item'}, $page_url], 'Looping:'.__LINE__.':');	

LOOP:

$mech->get($page_url);
#$mech->success or die $mech->response->status_line;
if(! $mech->success) {
	$news->write_log('Fail1 : ' . $h->{'item_id'} . ', [' . $page_url . '], ' . $h->{'item'});
	next;
}

# 页面的有效链接, 和翻页部分.
my $links = $news->get_links( $news->parse_list_page_1($mech->content));
$next_page = $news->get_next_page( $news->parse_list_page_2($mech->content));

if($next_page) {
	# 如果到了第三页,就返回,不必执行了.
	# $next_page="http://www.chinafnews.com/news/puguangtai/2.shtml"
	# 已经是最后一页了,跳过去.
	if (defined($current_page) && $next_page eq $current_page) {
		$page_url = '';
	}
	else {
		$current_page = $page_url;
		$page_url = $next_page;
	}
}
else {
	$page_url = '';
}


foreach my $url ( @{$links} ) {

	$mech->follow_link( url => $url );
	if(! $mech->success) {
		$news->write_log('Fail2 : ' . $page_url . ', [' . $h->{'item_id'} . '], ' . $url);
		next;
	}

	($h->{'linkname'}, $h->{'source'}, $h->{'pubdate'}, $h->{'content'})
		 = $news->parse_detail( $mech->content );

	# 如果'来源' is null，就要尝试没有‘来源’的解析。
	if(!defined($h->{'linkname'}) || $h->{'linkname'} eq '') {
		( $h->{'linkname'}, $h->{'pubdate'}, $h->{'content'} ) 
			= $news->parse_detail_without_from( $mech->content );
	}
	if(!defined($h->{'linkname'}) || $h->{'linkname'} eq '') {
		$news->write_log('Fail3! not to insert: ' . $page_url . ', [' . $h->{'item_id'} . '], ' . $url);
		next;
	}

	#通过了，插入数据库。
	$num ++;

	#$news->write_log($url); #.', item name:' . $h->{'item'});

	#patch
	#$h->{'pubdate'} = $news->patch_date(h->{'$pubdate'});
	$h->{'content'} = $news->patch_content($h->{'content'});

	$h->{'url'} = $dbh->quote($url);
	$h->{'author'} = $dbh->quote($url);
	 

	$h->{'linkname'} = $dbh->quote($h->{'linkname'});
	$h->{'source'} = $dbh->quote($h->{'source'}); # probably NULL.
	$h->{'content'} = $dbh->quote($h->{'content'});
	$h->{'pubdate'} = $dbh->quote($h->{'pubdate'});
	
	#$news->insert_contents($h);
	$news->insert_contexts($h);
		
	$mech->back();
}

$total += $num;
$news->write_log( "There are total [ $num ] records was processed succesfully for $page_url. \n");

goto LOOP if ($page_url);

}

$dbh->disconnect();

$end_time = time;
$news->write_log( "Total [$total] records, [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$news->close_log();

exit 8;


###### 帮助函数 #######

sub usage {
	print <<HELP;
Uage:
      $0
     or:
      $0 -n item #new item
     or:
      $0 -k keyword
     or:
      $0 -h  [-v]
Description:
  -n which item to scrape?
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
