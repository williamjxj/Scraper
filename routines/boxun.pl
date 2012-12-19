#!/usr/bin/perl -w
#Usage: boxun.pl -e 3

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use DBI;
use Getopt::Long;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use boxun;

# http://boxun.com/boxun/page1.shtml..http://boxun.com/boxun/page29.shtml
use constant SURL => q{http://boxun.com/boxun/page};

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

our ( $start_time, $end_time ) = ( 0,  0 );
our ( $page_url,   $num )      = ( '', 0 );
our ( $mech, $bx, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

# total and default is 10, use '-e 3' to scrape 3 pages.
my ( $start_from, $end_at, $version, $help ) = ( 1, 20, '1.0' );

usage()
  unless (
	GetOptions(
		'start=s' => \$start_from,
		'end=s'   => \$end_at,
		'help|?'  => \$help,
		'version' => \$version
	)
  );
$help && usage();

$start_time = time;

$dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

$bx = new boxun($dbh) or die $!;

our $h = {
	'createdby' => $dbh->quote('boxun.pl'),
	'category'  => $dbh->quote('博讯网'),
	'cate_id'   => 29,
	'item'      => $dbh->quote('博讯焦点'),
	'iid'       => 301
};

# http://boxun.com/boxun/page
our $surl  = SURL;
our $boxun = [
	[ 302, '大陆新闻',    'http://boxun.com/news/gb/china/page' ],
	[ 303, '国际新闻',    'http://www.peacehall.com/news/gb/intl/page' ],
	[ 304, '体育娱乐',    'http://boxun.com/news/gb/sport_ent/page' ],
	[ 305, '健康生活',    'http://boxun.com/news/gb/health/page' ],
	[ 306, '军事',          'http://boxun.com/news/gb/army/page' ],
	[ 307, '港澳台新闻', 'http://boxun.com/news/gb/taiwan/page' ],
	[ 308, '财经与科技', 'http://boxun.com/news/gb/finance/page' ],
	[ 309, '特别刊载',    'http://boxun.com/news/gb/z_special/page' ],
	[ 310, '不平则鸣',    'http://boxun.com/news/gb/yuanqing/page' ],
	[ 311, '社会万象',    'http://boxun.com/news/gb/misc/page' ],
	[ 312, '大众观点',    'http://boxun.com/news/gb/pubvp/page' ],
	[ 301, '博讯焦点',    'http://boxun.com/boxun/page' ]
];

$log = $bx->get_filename(__FILE__);
$bx->set_log($log);
$bx->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout(20);

foreach my $loop ( @{$boxun} ) {
	$h->{'iid'}  = $loop->[0];
	$h->{'item'} = $dbh->quote($loop->[1]);
	$surl        = $loop->[2];
	
	# 1..20..29
	foreach my $page ( $start_from .. $end_at ) {
		$page_url = $surl . $page . '.shtml';
		$h->{'author'} = $dbh->quote($page_url);

		$mech->get($page_url);
		$mech->success or die $mech->response->status_line;

		# $mech->save_content('bx1.html'); exit;
		my $html = $mech->content;

		my $newslist = $bx->strip_newslist($html);

		my $aoh = $bx->parse_newslist($newslist);

		my $detail;

		foreach my $p ( @{$aoh} ) {
			my $url = $p->[0];

			$num++;
			$mech->follow_link( url => $url );
			$mech->success or next;

			# $mech->save_content('bx2.html'); exit;
			$detail = $bx->strip_detail( $mech->content );
			my ( $title, $pubdate, $desc, $source ) =
			  $bx->parse_detail($detail);
			next unless $desc;

			if ( $p->[0] =~ m/boxun.com/i ) {
				$h->{'url'} = $dbh->quote( $p->[0] );
			}
			else {
				$h->{'url'} = $dbh->quote( 'http://boxun.com' . $p->[0] );
			}
			$h->{'title'}  = $dbh->quote( $p->[1] );
			$h->{'source'} = $dbh->quote($source);
			$h->{'clicks'} = $bx->generate_random();

			# 来自细节页面。
			$h->{'detail_title'} = $dbh->quote($title);
			$h->{'pubdate'}      = $dbh->quote($pubdate);
			$h->{'desc'}         = $dbh->quote($desc);

			# 构造数据。
			$h->{'likes'}   = $bx->generate_random(100);
			$h->{'guanzhu'} = $bx->generate_random(100);

			my $sql = qq{  insert ignore into contents_3(
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
				now(),
				$h->{'desc'}
			)
	};
			$dbh->do($sql);
			$mech->back();
		}
	}
}

END {
	$dbh->disconnect();
	$end_time = time;
	$bx->write_log(
		    "There are total [ $num ] records was processed succesfulbx!, [ "
		  . ( $end_time - $start_time )
		  . " ] seconds used.\n" );
	$bx->write_log("==============================================\n");
	$bx->close_log();
	exit 6;
}

sub usage {
	print <<HELP;
Uage:
      $0
     or:
      $0 -h  [-v]
Description:
  -s start from
  -e end at
  -h this help
  -v version

Examples:
     (1) $0     # use default
     (2) $0 -s 1 -e 2 #multi1.shtm to multi2.shtm
     (5) $0 -h  # get help
     (6) $0 -v  # get version

HELP
	exit 3;
}
