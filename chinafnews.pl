#! /opt/lampp/bin/perl -w
###! /cygdrive/c/Perl/bin/perl.exe -w

use lib qw(./lib/);
use config;
use db;
use chinafnews;

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

our ( $dbh, $sth );

our ( $start_url, $page_url,  $next_page )   = ( q{http://www.chinafnews.com/news/hot/}, undef, undef );

our ( $num,  $start_time, $end_time, $end_date ) = ( 0,     0,     0, '' );

our ($cate_id, $createdby) = (3, '网页自动抓取程序');
my  ($chan_id, $chan_name, $created);

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};

$createdby = $dbh->quote($createdby);

# 初始化页面抓取模块:
$news = new chinafnews( $db->{dbh} ) or die;

# 日志文件:
$start_time = time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . __FILE__ . "]: start at: [" . localtime() . "]." );

##### 判别输入粗参数部分:
my ( $list, $todate, $channel, $keywords, $help, $version ) = ( undef, undef, undef, undef, undef, undef );
usage()
  unless (
	GetOptions(
		'list'       => \$list,
		'todate=s'   => \$todate,
		'channel=s'  => \$channel,
		'keywords=s' => \$keywords,
		'help|?'     => \$help,
		'version'    => \$version
	)
  );
  
$help && usage();

# 判断是否有输入参数?
if ($list) {
	my $list = $news->select_channels();
	foreach my $channels (@$list) {
		print $channels->[0] . "\n";
	}
	exit 2;
}
# date +'%a %d %b' -d "2 day ago"
if ($todate) {
	$end_date = $news->get_end_date($todate);
}
else {
	$todate =  INTERVAL_DATE;	
}

my ($queue) = [];
if($channel) {
	$queue = $news->select_channel_by_id($channel);
}
else {
	$queue= $news->select_channels();
}
#print Dumper(@queue);

#if ($keywords) {
#	$keywords = '食品';
#	$news->select_keywords(utf8::encode($keywords));
#}
if ($version) {
	print VERSION;
	exit;
}

########### 正式 抓取

$mech = WWW::Mechanize->new( autocheck => 0 );

# 第一次从首页开始抓取,以后取'下一页'的链接,继续抓取.
foreach my $li (@{$queue}) {
	print Dumper($li);
	$news->write_log($li, 'Looping:'.__LINE__.':');	

	$chan_id = $li->[0];
	$chan_name = $dbh->quote($li->[2]);
	#$chan_name = $li->[2];
	$page_url = 'http://www.chinafnews.com/news/' . $li->[1];
	$num = 0; #将循环计数复位.

LOOP:

$mech->get($page_url);
#$mech->success or die $mech->response->status_line;
$mech->success or next;


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
	$mech->success or next;

	# print $mech->content;

	$num ++;
	
	my ( $name, $notes, $published_date, $content ) = $news->parse_detail( $mech->content );

	$name = $dbh->quote($name);
	$notes = $dbh->quote($notes);
	$content = $dbh->quote($content);
	$published_date = $dbh->quote($published_date);

print $name. "\n";
print $notes . "\n";
print $published_date."\n";
	
	my $sql = qq{ insert ignore into contents
			(linkname,
			notes,
			cate_id,
			chan_id, 
			chan_name, 
			published_date,
			createdby,
			created,
			content
		) values(
			$name, 
			$notes,
			$cate_id,
			$chan_id, 
			$chan_name,
			$published_date,
			$createdby,
			now(),
			$content
		)};
	
	# $news->write_log($sql, 'insert:'.$num.':');
	$sth = $dbh->do($sql);
	
	$mech->back();
}

$news->write_log( "There are total [ $num ] records was processed succesfully for $page_url. \n");

goto LOOP if ($page_url);

}

$dbh->disconnect();

$end_time = time;
$news->write_log( "Total [$todate] days' data (end at: $end_date): [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
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
