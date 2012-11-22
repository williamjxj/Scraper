#!/usr/bin/perl -w

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
our ( $page_url, $num ) = ( '', 0 );
our ( $mech, $dwn, $log ) = ( undef, undef, undef );
our ( $dbh, $sth );

my ( $start_from, $end_at, $version, $help ) = ( 1, 100, '1.0' );
my ( $todate, $end_date );

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

#foreach my $page ( (2) )
# 1..100
foreach my $page ( $start_from .. $end_at ) {
	if ( $page != 1 ) {
		$page_url = SURL . 'index' . $page . '.shtm';
	}

	$h->{'author'} = $dbh->quote($page_url);

	$mech->get($page_url);
	$mech->success or die $mech->response->status_line;

	# $mech->save_content('dw1.html');

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

		# $mech->save_content('dw2.html'); exit;

		$detail = $dwn->strip_detail( $mech->content );
		my ( $title, $pubdate, $desc ) = $dwn->parse_detail($detail);

		#undef: next if($title eq '' || $desc eq '');
		unless ( defined $desc ) {
			$mech->back();
			next;
		}

		#来自列表页面。
		if ( $p->[1] =~ m/http:/i ) {
			$h->{'url'} = $dbh->quote( $p->[1] );
		}
		else {
			$h->{'url'} = $dbh->quote( PRES . $p->[1] );
		}
		$h->{'title'}   = $dbh->quote( $p->[2] );
		$h->{'created'} = $dbh->quote( $p->[0] );

		# 来自细节页面。
		$h->{'detail_title'} = $dbh->quote($title);           #tags.
		$h->{'source'}       = $dbh->quote('多维新闻');

		$h->{'pubdate'} = $dbh->quote($pubdate);
		$h->{'desc'}    = $dbh->quote($desc);                 #content

		# 构造数据。
		$h->{'clicks'}  = $dwn->generate_random();
		$h->{'likes'}   = $dwn->generate_random(100);
		$h->{'guanzhu'} = $dwn->generate_random(100);

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
	$dwn->write_log(
		    "There are total [ $num ] records was processed succesfully!, [ "
		  . ( $end_time - $start_time )
		  . " ] seconds used.\n" );
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

