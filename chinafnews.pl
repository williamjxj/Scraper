#! /opt/lampp/bin/perl -w
###! /cygdrive/c/Perl/bin/perl.exe -w

use lib qw(./lib/);
use config;

use db;
use chinafnews;

use warnings;
use strict;
use utf8;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

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

our ( $start_url, $page_url,  $next_page )   = ( URL3, undef, undef );

our ( $num,  $start_time, $end_time, $end_date ) = ( 0,     0,     0, '' );

my($cate_id, $db_name, $createdby, $chan_id, $chan_name, $created) = (3, DBNAME, '网页自动抓取程序');

# 页面的有效链接, 和翻页部分.
my ($links, $next);

# 初始化数据库:
my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";
$db = new db( $user, $pass, $dsn );
$dbh = $db->{dbh};


# 初始化页面抓取模块:
$news = new chinafnews( $db->{dbh} ) or die;

# 日志文件:
$start_time = localtime() . time;

$log = $news->get_filename(__FILE__);
$news->set_log($log);
$news->write_log( "[" . $log . "]: start at: [" . $start_time . "]." );


##### 判别输入粗参数部分:
my ( $first, $list, $todate, $channel, $item, $keywords, $help, $version ) = ( undef, undef, undef, undef, undef, undef, undef );
usage()
  unless (
	GetOptions(
		'first'      => \$first,
		'list'       => \$list,
		'todate=s'   => \$todate,
		'channel=s'  => \$channel,
		'item=s'     => \$item,
		'keywords=s' => \$keywords,
		'help|?'     => \$help,
		'version'    => \$version
	)
  );
  
$help && usage();

# 判断是否有输入参数?
if ($first) {
	my $ca1 = $news->select_items();
	foreach my $ca2 (@$ca1) {
		print Dumper($ca2);
		print $ca2->[0] . "\n";
	}
	exit 1;
}
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

my ($chs, @queue) = ([], ());
if($channel) {
	$chs = $news->select_channel_by_id($channel);
	push(@queue, URL2 . $chs->[1]);
}
else {
	$chs= $news->select_channels();
	foreach my $ch (@{$chs}) {
		push(@queue, URL2 . $ch->[1]);
	}
}
print Dumper(\@queue);


if($item) {
	$news->select_items_by_cid($item);	
}
if ($keywords) {
	$keywords = '食品';
	$news->select_keywords(utf8::encode($keywords));
}
#
#if ($version) {
#	get_ver();
#}


########### 正式 抓取

$mech = WWW::Mechanize->new( autocheck => 0 );

LOOP:

# 第一次从首页开始抓取,以后取'下一页'的链接,继续抓取.
if (defined($next_page)) {
	$page_url = $next_page;
}
else {
	$page_url = $start_url;	
}

$mech->get($page_url);
$mech->success or die $mech->response->status_line;


$links = $news->get_links( $news->parse_list_page_1($mech->content) );
$next = $news->get_next_page( $news->parse_list_page_2($mech->content) );

print Dumper($links);
print Dumper($next);


$chan_name = $dbh->quote(utf8::encode('饮食健康'));

$chan_id = $news->select_channel_by_name($chan_name);

foreach my $url ( @{$links} ) {

	$mech->follow_link( url => $url );
	$mech->success or next;

	# print $mech->content;

	my ( $name, $notes, $created, $content ) = $news->parse_detail( $mech->content );

	$name = $dbh->quote($name);
	$notes = $dbh->quote($notes);
	$content = $dbh->quote($content);
	$created = $dbh->quote($created);
	$createdby = $dbh->quote(utf8::encode($createdby));
	
	my $sql = q{ insert ignore into } . $db_name . 
		qq{
			(name,
			notes,
			content,
			cate_id,
			chan_id, 
			chan_name, 
			createdby,
			created 
		) values(
			$name, 
			$notes,
			$content,
			$cate_id,
			$chan_id,
			$chan_name,
			$createdby,
			$created
		)};
	
	print $sql;
		
	$sth = $dbh->do($sql);

exit;	
	$mech->back();
}

goto LOOP if ($page_url);

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
sub get_ver()
{
	print <<EOF;

$0:  Version 2.0
EOF
	exit 2;
}
