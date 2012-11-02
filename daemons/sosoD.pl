#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);

use Proc::Daemon;
use Fcntl;
use feature qw(say);
use FileHandle;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use soso;

use constant SURL     => q{http://www.soso.com};
use constant DHOME    => '/home/williamjxj/scraper/';
use constant NP_SOSO => DHOME . '.soso';

BEGIN {
	unless ( -p NP_SOSO ) {
		if ( system( "mknod", NP_SOSO, "p" ) && system( "mkfifo", NP_SOSO ) )
		{
			die "mk{nod,fifo} NP_SOSO failed";
		}
	}
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	$ENV{PATH} .= "/home/williamjxj/scraper/:/home/williamjxj/scraper/bin:";
	local ($|) = 1;
	undef $/;
}

Proc::Daemon::Init;

our $dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

my $ss = new soso($dbh);

=comment
定义插入数组的缺省值.
keyword: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'soso'
=cut

my $h = {
	'source'    => $dbh->quote(SURL),
	'createdby' => $dbh->quote( $ss->get_os_stripname(__FILE__) ),
};

my $mech = WWW::Mechanize->new() or die;
$mech->timeout(30);

#####################################################
chdir();
sysopen( FIFO, NP_SOSO, O_RDONLY ) or die "$!";
my $fh = new FileHandle( DHOME . "logs/soso.log", "w" ) or die "$!";
$fh->autoflush(1);

while (1) {
	my $php_input = <FIFO>;
	if ($php_input) {
		my $keyword = $php_input;
		print $fh $keyword . "\n";
		$keyword = decode( "utf-8", $keyword );
		$h->{'keyword'} = $dbh->quote($keyword);

		$mech->get(SURL);
		#$mech->success or die $mech->response->status_line;
		$mech->success or next;

		$mech->submit_form(
			form_name => 'flpage',
			fields    => { w => $keyword }
		);
		$mech->success or next; #die $mech->response->status_line;

		# 保存查询的url, 上面有字符集, 查询数量等信息.
		$h->{'author'} = $dbh->quote( $mech->uri()->as_string )
		  if ( $mech->uri );

		my $t = $ss->strip_result( $mech->content );

		my $aoh = $ss->parse_result($t);

		my $kid = $ss->get_kid_by_keyword($keyword);

		if ($kid) {
			my ( $rks, $html, $rkey, $rurl, $sql ) = ( [] );

			$html = $ss->strip_related_keywords( $mech->content );

			$rks = $ss->get_related_keywords($html) if $html;

			#保存soso的相关搜索关键词.
			foreach my $r ( @{$rks} ) {
				$rkey = $dbh->quote( $r->[1] );
				$rurl = $dbh->quote( SURL . $r->[0] );
				$sql  = qq{
			insert ignore into key_related(rk, kurl, kid, keyword, createdby, created)
			values(
				$rkey,
				$rurl,
				$kid,
				$h->{'keyword'},
				$h->{'createdby'},
				now()
			)
		};
				$dbh->do($sql);
			}
		}

		my $sql;
		foreach my $p ( @{$aoh} ) {
			$h->{'url'}   = $dbh->quote( $p->[0] );
			$h->{'title'} = $dbh->quote( $p->[1] );
			$h->{'desc'}  = $dbh->quote( $p->[2] );

 # 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
			$h->{'pubdate'} = $dbh->quote( $ss->get_time('2') );

			$h->{'clicks'}  = $ss->generate_random();
			$h->{'likes'}   = $ss->generate_random(100);
			$h->{'guanzhu'} = $ss->generate_random(100);

			$sql = qq{ insert ignore into contents(
		title,
		url,
		author,
		source,
		pubdate,
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
		$h->{'keyword'},
		$h->{'clicks'},
		$h->{'likes'},
		$h->{'guanzhu'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)};
			$dbh->do($sql);
		}
	}
}

close(FIFO);
$dbh->disconnect();
exit 6;

