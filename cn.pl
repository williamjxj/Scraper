#! /opt/lampp/bin/perl -w
# in cygwin, use: $ perl cn.pl
#本程序操作contexts表。

use lib qw(./lib/);
use config;
use db;
use chinafnews;

use warnings;
use strict;
#如果没有此句，createdby中文显示就不正确。
use utf8;
#use DateTime;
#use feature qw(say);
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;
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
our ( $mech, $db, $news, $log ) = ( undef, undef );

our ( $dbh, $sth );

my ( $page_url, $next_page )   = ( undef, undef );

my ( $num, $total, $start_time, $end_time, $end_date ) = ( 0, 0, 0, 0, '' );

our $links;

my ($cate_id, $queue, $chan_id, $chan_name) = (3, [], 0, undef);

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

our $createdby = '网页抓取程序';
$createdby = $dbh->quote($createdby);

# 初始化页面抓取模块:
$news = new chinafnews( $db->{dbh} ) or die;

# 日志文件:
$start_time = time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . __FILE__ . "]: start at: [" . localtime() . "]." );

##### 判别输入粗参数部分:
my ($todate, $channel, $keywords, $help, $version) = (undef, undef, undef, undef, undef);
my ($aurl, $file) = (undef, undef);
usage()
  unless (
	GetOptions(
		'aurl=s'	 => \$aurl,
		'file=s'	=> \$file,
		'todate=s'   => \$todate,
		'channel=s'  => \$channel,
		'keywords=s' => \$keywords,
		'help|?'     => \$help,
		'version'    => \$version
	)
  );
  
$help && usage();

# 判断是否有输入参数?

# date +'%a %d %b' -d "2 day ago"
if ($todate) {
	$end_date = $news->get_end_date($todate);
}
else {
	$todate =  INTERVAL_DATE;	
}

if($channel) {
	$queue = $news->select_channel_by_id($channel);
}
else {
	$queue= $news->select_channels();
}

if ($keywords) {
	#my $kws = $news->select_keywords(utf8::encode($keywords));
	my $kws = $news->select_keywords($keywords);
	print Dumper($kws);
	exit;
}
if ($version) {
	print VERSION;
	exit;
}

########### 正式 抓取

$mech = WWW::Mechanize->new( autocheck => 0 );
if ($aurl) {
	print $aurl."\n";
	$mech->get($aurl);
	$mech->success or die $mech->response->status_line;
	print($mech->content);
	exit;
	my ( $name, $notes, $published_date, $content ) = $news->parse_detail( $mech->content );
	if($name eq '') {
		( $name, $published_date, $content ) = $news->parse_detail_without_from( $mech->content );
	}
	print $name . "\n";
	print $notes . "\n";
	print $published_date . "\n";
	print $content . "\n";
	exit 10;
}
# 对于上次处理失败的case,再次处理一遍。
#($tid, $turl) = ($_ =~ m /(.*),(.*)/);
if ($file) {
	# 这里,file就是channel_id的意思.
	$chan_id = $file or 0;
	$page_url = ''; #这样就不会循环了.
	open FILE, "< ./logs/again.txt" or die $!;
	while (<FILE>) {
		chomp;
		push(@{$links}, $_);
	}
	close(FILE);
	my $h = {};
	$dbh->insert_contexts($h);
}

# 第一次从首页开始抓取,以后取'下一页'的链接,继续抓取.
foreach my $li (@{$queue}) {
	$chan_id = $li->[0];
	$chan_name = $dbh->quote($li->[2]);
	$page_url = BASEURL . $li->[1];
	$num = 0; #将循环计数复位.
	$news->write_log([$chan_id, $chan_name, $page_url], 'Looping:'.__LINE__.':');	

LOOP:

$mech->get($page_url);
#如果失败，不退出，而是继续循环下一个。
#$mech->success or die $mech->response->status_line;
if(! $mech->success) {
	$news->write_log('Fail1 : ' . $chan_id . ', [' . $page_url . '], ' . $chan_name);
	next;
}

# 页面的有效链接, 和翻页部分.
my $links = $news->get_links( $news->parse_list_page_1($mech->content));
$next_page = $news->get_next_page( $news->parse_list_page_2($mech->content));

if($next_page) {
	$page_url = $next_page;
}
else {
	$page_url = '';
}

foreach my $url ( @{$links} ) {

	$mech->follow_link( url => $url );
	if(! $mech->success) {
		$news->write_log('Fail2 : ' . $page_url . ', [' . $chan_id . '], ' . $url);
		next;
	}

	my ( $name, $notes, $published_date, $content ) = $news->parse_detail( $mech->content );

	# 如果'来源' is null，就要尝试没有‘来源’的解析。
	if(!defined($name) || $name eq '') {
		( $name, $published_date, $content ) = $news->parse_detail_without_from( $mech->content );
	}
	if(!defined($name) || $name eq '') {
		$news->write_log('Fail3! not to insert: ' . $page_url . ', [' . $chan_id . '], ' . $url);
		next;
	}

	#通过了，插入数据库。
	$num ++;

	$news->write_log($url); #.', channel name:' . $chan_name);

	#patch
	$published_date = $news->patch_date($published_date);
	$content = $news->patch_content($content);


	$name = $dbh->quote($name);
	$notes = $dbh->quote($notes);
	$content = $dbh->quote($content);
	$published_date = $dbh->quote($published_date);
	
	my $sql = qq{ insert ignore into contexts
			(name,
			notes,
			content,
			cate_id,
			chan_id, 
			chan_name, 
			published_date,
			createdby,
			created 
		) values(
			$name, 
			$notes,
			$content,
			$cate_id,
			$chan_id,
			$chan_name,
			$published_date,
			$createdby,
			now()
		)};
	
	#$news->write_log($sql, 'insert:'.$num.':');
	#print $sql . "\n";
	$sth = $dbh->do($sql);
	$mech->back();
}

$total += $num;
$news->write_log( "There are total [ $num ] records was processed succesfully for $page_url, $chan_name, $chan_id!\n");

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
      $0 -n channel_name #new channel
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