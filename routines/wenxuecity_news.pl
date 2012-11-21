#!/usr/bin/perl -w

=head1 NAME
参考：
$ mech-dump --forms http://www.wenxuecity.com

$mech->links()
$mech->follow_link(~);
die "Foo link failed: ", $mech->response->status_line unless $mech->success; 

$mech->save_content(~);
$mech->get('http://www.cpan.org/src/stable.tar.gz',':content_file' => 'stable.tar.gz');

由于要放在crontab中执行，所以要用绝度路径。
=cut

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use DBI;
use File::Basename;
use FileHandle;
use Data::Dumper;
use Encode;
use Getopt::Long;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use wenxuecity;

use constant SURL => q{http://www.wenxuecity.com/news/1};
use constant PRES => q{http://www.wenxuecity.com/news/};

BEGIN {
    $SIG{'INT'}  = 'IGNORE';
    $SIG{'QUIT'} = 'IGNORE';
    $SIG{'TERM'} = 'IGNORE';
    $SIG{'PIPE'} = 'IGNORE';
    $SIG{'CHLD'} = 'IGNORE';
	binmode STDOUT, ':utf8';
	local ($|) = 1;
	undef $/;
}

our ( $start_time, $end_time ) = ( 0, 0 );
our ( $end_date, $todate ) = ( undef, INTERVAL_DATE );
our ( $page_url, $num ) = ('', 0);
our ( $mech, $wxc, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

=head1 SYNOPSIS
$start_time: 开始运行时间。
$end_time: 结束时间。
$todate: 从命令行指定的数字，几天之前，比如3表示3天之前。($todate,$end_date)一起使用。缺省：2.
$end_date: scrape到哪一天，格式：2012-11-20， 2012-11-08
$page_url: 动态的 当前执行的URL.比如：http://www.wenxuecity.com/news/1, http://www.wenxuecity.com/news/16
$num: 统计数目：共有多少条记录插入。
其余:
$dbh, $sth: 数据库句柄。
用File::Basename模块代替
=cut

my ( $version, $help );
usage()
  unless (
	GetOptions(
		'todate=s'   => \$todate,
		'help|?'  => \$help,
		'version' => \$version
	)
  );
$help && usage();

$start_time = time;

$dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

$wxc = new wenxuecity( $dbh ) or die $!;

our $h = {
	'createdby'	=> $dbh->quote('wenxuecity_news.pl'),
	'category'	=> $dbh->quote('文学城'),
	'cate_id'	=> 26,
	'item'		=> $dbh->quote('滚动新闻'),
	'iid'		=> 295
};

# 日志文件处理：
my($file, $dir, $suffix) = fileparse(__FILE__, qr/\[^.]*/);
#$log = new FileHandle( $file, RW_MODE ) or die "$!";
#$log->autoflush(1);

$log = $wxc->get_filename(__FILE__);
$wxc->set_log($log);
$wxc->write_log( "[" . $log . "]: start at: [" . localtime() . "]."
);


# 决定scrape到哪一天。
if ($todate) {
	$end_date = $wxc->get_end_date($todate);
}

#
$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout(20);

#
$page_url = SURL;

LOOP:
#$mech->get($page_url, ':content_file' => 'w1.html');
$mech->get($page_url);
$mech->success or die $mech->response->status_line;

# 保存当前的page_url.
$h->{'author'} = $dbh->quote($page_url);

# $mech->save_content('w2.html');

my $html = $mech->content;

my $pagenav = $wxc->strip_pagenav($html);
my $newslist = $wxc->strip_newslist($html);

$page_url = PRES . $wxc->parse_next_page($pagenav);

my $aoh = $wxc->parse_newslist($newslist);

my $detail;

foreach my $p ( @{$aoh} ) {
	my $url = $p->[0];

	$num++;
	$mech->follow_link( url => $url );
	$mech->success or next;

	#$mech->save_content('w2.html'); exit;
	
	$detail = $wxc->strip_detail($mech->content);
	my ($title, $source, $pubdate, $clicks, $desc) = $wxc->parse_detail($detail);

	#来自列表页面。
	$h->{'url'}   = $dbh->quote( PRES . $p->[0] );
	$h->{'title'} = $dbh->quote( $p->[1] );
	$h->{'created'} = $dbh->quote($p->[2]);
	
	# 来自细节页面。
	$h->{'detail_title'} = $dbh->quote($title);
	$h->{'source'} = $dbh->quote($source);
	$h->{'pubdate'} = $dbh->quote( $pubdate );
	$h->{'clicks'}  = $clicks ? $clicks : $wxc->generate_random();
	$h->{'desc'}  = $dbh->quote( $desc );

	# 构造数据。
	$h->{'likes'}   = $wxc->generate_random(100);
	$h->{'guanzhu'} = $wxc->generate_random(100);

	my $sql = qq{  insert ignore into contents_2(
				title,
				url,
				author,
				source,
				pubdate,
				category,
				cate_id,
				item,
				iid,
				tags,
				clicks,
				likes,
				guanzhu,
				createdby,
				created,
				content
			) values(
				$h->{'title'},
				$h->{'url'},
				$h->{'author'},
				$h->{'source'},
				$h->{'pubdate'},
				$h->{'category'},
				$h->{'cate_id'},
				$h->{'item'},
				$h->{'iid'},
				$h->{'detail_title'},
				$h->{'clicks'},
				$h->{'likes'},
				$h->{'guanzhu'},
				$h->{'createdby'},
				$h->{'created'},
				$h->{'desc'}
			)
	};
	$dbh->do($sql);
	$mech->back();
}

goto LOOP if ($page_url);

END {
  $dbh->disconnect();
  $end_time = time;
  $wxc->write_log(
	      "Terminated: Total [$todate] days' data (end at: $end_date): [ "
		. ( $end_time - $start_time )
		. " ] seconds used.\n" );

  $wxc->write_log(
"There are total [ $num ] records was processed succesfully!\n" );
  $wxc->write_log("==============================================\n");
  $wxc->close_log();
  exit 6;
}

sub usage {
	print <<HELP;
Uage:
      $0
     or:
      $0 -h  [-v]
Description:
  -t from what date to download? default it's from 2 days before.
  -h this help
  -v version

Examples:
     (1) $0     # use default
     (5) $0 -h  # get help
     (6) $0 -v  # get version

HELP
	exit 3;
}
