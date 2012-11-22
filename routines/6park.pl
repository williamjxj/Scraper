ll#!/usr/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use DBI;
use FileHandle;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use liuyuan;

use constant SURL => q{http://www.6park.com/news/multi1.shtml};
use constant PRES => q{http://www.6park.com/news/};

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
our ($todate) = (INTERVAL_DATE);
our ( $page_url, $num ) = ( '', 0 );
our ( $mech, $ly, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

$start_time = time;

$dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

$ly = new liuyuan($dbh) or die $!;

our $h = {
	'createdby' => $dbh->quote('6park.pl'),
	'category'  => $dbh->quote('6park'),
	'cate_id'   => 27,
	'item'      => $dbh->quote('新闻速递'),
	'iid'       => 298
};

$log = $ly->get_filename(__FILE__);
$ly->set_log($log);
$ly->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );


$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout(20);

foreach my $page ( 1 .. 10 ) {
	$page_url = 'http://www.6park.com/news/multi' . $page . '.shtml';
	$h->{'author'}       = $dbh->quote($page_url);

	$mech->get($page_url);
	$mech->success or die $mech->response->status_line;

	# $mech->save_content('6park1.html'); exit;
	my $html = $mech->content;

	my $newslist = $ly->strip_newslist($html);

	# $href,$title,$source,$created,$clicks
	my $aoh = $ly->parse_newslist($newslist);

	my $detail;

	foreach my $p ( @{$aoh} ) {
		my $url = $p->[0];

		$num++;
		$mech->follow_link( url => $url );
		$mech->success or next;

		#$mech->save_content('6park2.html'); exit;

		$detail = $ly->strip_detail( $mech->content );
		my ( $title, $pubdate, $desc, $source1 ) = $ly->parse_detail($detail);

		# $source1 和$p->[2]应该一样，是从list页面， detail页面抓取的。
		#来自列表页面。
		$h->{'url'}     = $dbh->quote( $p->[0] );
		$h->{'title'}   = $dbh->quote( $p->[1] );
		$h->{'source'}  = $dbh->quote( $p->[2] );
		$h->{'created'} = $dbh->quote( $p->[3] );
		$h->{'clicks'}  = $p->[4] ? $p->[4] : $ly->generate_random();

		# 来自细节页面。
		$h->{'detail_title'} = $dbh->quote($title);
		$h->{'pubdate'}      = $dbh->quote($pubdate);
		$h->{'desc'}         = $dbh->quote($desc);

		# 构造数据。
		$h->{'likes'}   = $ly->generate_random(100);
		$h->{'guanzhu'} = $ly->generate_random(100);

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
	$ly->write_log(
		    "Terminated: Total [$todate] days' data: [ "
		  . ( $end_time - $start_time )
		  . " ] seconds used.\n" );

	$ly->write_log(
		"There are total [ $num ] records was processed succesfully!\n");
	$ly->write_log("==============================================\n");
	$ly->close_log();
	exit 6;
}
