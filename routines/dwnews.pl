#!/usr/bin/perl -w

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
use dwnews;

use constant SURL => q{http://china.dwnews.com/highlights/};
use constant PRES => q{http://china.dwnews.com/};

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
our ( $page_url, $num ) = ( 'http://china.dwnews.com/highlights/', 0 );
our ( $mech, $dwn, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

$start_time = time;

$dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

$dwn = new dwnews($dbh) or die $!;

our $h = {
	'createdby' => $dbh->quote('dwnews.pl'),
	'category'  => $dbh->quote('多维新闻网'),
	'cate_id'   => 28,
	'item'      => $dbh->quote('要闻'),
	'iid'       => 299
};

$log = $dwn->get_filename(__FILE__);
$dwn->set_log($log);
$dwn->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

#
$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout(20);

foreach my $page ( 1 .. 10 )
{
	if ( $page != 1 ) {
		$page_url = 'http://china.dwnews.com/highlights/index' . $page . '.shtm';
	}

	$h->{'author'} = $dbh->quote($page_url);

	$mech->get($page_url);
	$mech->success or die $mech->response->status_line;
	$mech->save_content('dw1.html');

	my $html = $mech->content;

	my $newslist = $dwn->strip_newslist($html);

	my $aoh = $dwn->parse_newslist($newslist);

	my $detail;

	# created, link, title
	foreach my $p ( @{$aoh} ) {
		my $url = $p->[1];

		$num++;
		$mech->follow_link( url => $url );
		$mech->success or next;

		$mech->save_content('dw2.html'); exit;

		$detail = $dwn->strip_detail( $mech->content );
		my ( $title, $source, $pubdate, $clicks, $desc ) =
		  $dwn->parse_detail($detail);

		#来自列表页面。
		$h->{'url'}     = $dbh->quote( PRES . $p->[1] );
		$h->{'title'}   = $dbh->quote( $p->[2] );
		$h->{'created'} = $dbh->quote( $p->[0] );

		# 来自细节页面。
		$h->{'detail_title'} = $dbh->quote($title);
		$h->{'source'}       = $dbh->quote($source);

		$h->{'pubdate'} = $dbh->quote($pubdate);
		$h->{'clicks'}  = $clicks ? $clicks : $dwn->generate_random();
		$h->{'desc'}    = $dbh->quote($desc);

		# 构造数据。
		$h->{'likes'}   = $dwn->generate_random(100);
		$h->{'guanzhu'} = $dwn->generate_random(100);

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
	$dwn->write_log(
		    "Terminated: Total [$todate] days' data: [ "
		  . ( $end_time - $start_time )
		  . " ] seconds used.\n" );

	$dwn->write_log(
		"There are total [ $num ] records was processed succesfully!\n");
	$dwn->write_log("==============================================\n");
	$dwn->close_log();
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
