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
use Getopt::Long;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use wenxuecity;

use constant SURL => q{http://www.wenxuecity.com/news/gossip/};

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

our ( $page_url, $num ) = ( '', 0 );
our ( $mech, $wxc, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

my ( $start_from, $end_at, $version, $help ) = ( 583, 1155, '1.0' );
my ( $todate, $end_date );

usage()
  unless (
	GetOptions(
		'start=s'  => \$start_from,
		'end=s'    => \$end_at,
		'todate=s' => \$todate,
		'help|?'   => \$help,
		'version'  => \$version
	)
  );
$help && usage();

$start_time = time;

$dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

$wxc = new wenxuecity($dbh) or die $!;

our $h = {
	'createdby' => $dbh->quote('wenxuecity_gossip.pl'),
	'category'  => $dbh->quote('文学城'),
	'cate_id'   => 26,
	'item'      => $dbh->quote('生活百态'),
	'iid'       => 297
};

$log = $wxc->get_filename(__FILE__);
$wxc->set_log($log);
$wxc->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

# 如果指定了 $todate, 则它有优先级，决定scrape到哪一天。
# 参数 ‘-t’ 和 '-t 10'都工作。
if ( defined $todate ) {
	$todate = INTERVAL_DATE unless $todate;
	$end_date = $wxc->get_end_date($todate);
}

#
$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout(20);

# 在执行之前，再一次确认有值。
$start_from = 1 unless $start_from;
$end_at     = 3 unless $end_at;

foreach my $page ( $start_from .. $end_at ) 
{
	$page_url = SURL . $page;
	# 保存当前的page_url.
	$h->{'author'} = $dbh->quote($page_url);
	
	$mech->get($page_url);
	$mech->success or die $mech->response->status_line;

	my $html = $mech->content;

	my $newslist = $wxc->strip_newslist($html);

	my $aoh = $wxc->parse_newslist($newslist);

	my $detail;

	foreach my $p ( @{$aoh} )
	{
		#字符用eq, 数字用==
		exit if ( $end_date && ($p->[2] eq $end_date));
		
		my $url = $p->[0];

		$num++;
		$mech->follow_link( url => $url );
		$mech->success or next;

		$detail = $wxc->strip_detail( $mech->content );
		my ( $title, $source, $pubdate, $clicks, $desc ) =
		  $wxc->parse_detail($detail);

		#来自列表页面。
		$h->{'url'}     = $dbh->quote( SURL . $p->[0] );
		$h->{'title'}   = $dbh->quote( $p->[1] );
		$h->{'created'} = $dbh->quote( $p->[2] );

		# 来自细节页面。
		$h->{'detail_title'} = $dbh->quote($title);
		$h->{'source'}       = $dbh->quote($source);
		$h->{'pubdate'}      = $dbh->quote($pubdate);
		$h->{'clicks'}       = $clicks ? $clicks : $wxc->generate_random();
		$h->{'desc'}         = $dbh->quote($desc);

		# 构造数据。
		$h->{'likes'}   = $wxc->generate_random(100);
		$h->{'guanzhu'} = $wxc->generate_random(100);

		my $sql = qq{  insert ignore into } . CONTENTS_NEW . qq{(
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
}

END {
	$dbh->disconnect();
	$end_time = time;
	if ($todate) {
		$wxc->write_log(
			    "Done: Total [$todate] days' data (end at: $end_date): [ "
			  . ( $end_time - $start_time )
			  . " ] seconds used.\n" );
	}
	$wxc->write_log(
		    "There are total [ $num ] records was processed succesfully!, [ "
		  . ( $end_time - $start_time )
		  . " ] seconds used.\n" );
	$wxc->write_log("==============================================\n");
	$wxc->close_log();
	exit 9;
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
     (2) $0 -s 2 -e 20 #from /news/2 to /news/20.
     (3) $0 -t 3 #三天之内的within 3 days.
     (4) $0 -t 7 -s 2 -e 100 #下载http://www.wenxuecity.com/news/2到/news/100页面，并且，出版天数要在7天之内。
     (5) $0 -h  # get help
     (6) $0 -v  # get version

HELP
	exit 3;
}
