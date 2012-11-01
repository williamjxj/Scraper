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
use yahoo;

use constant SURL     => q{http://search.yahoo.com/};
use constant DHOME    => '/home/williamjxj/scraper/';
use constant NP_YAHOO => DHOME . '.yahoo';

BEGIN {
	unless ( -p NP_YAHOO ) {
		if ( system( "mknod", NP_YAHOO, "p" ) && system( "mkfifo", NP_YAHOO ) )
		{
			die "mk{nod,fifo} NP_YAHOO failed";
		}
	}
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	$ENV{PATH} .= "/home/williamjxj/scraper/:/home/williamjxj/scraper/daemons/:";
	local ($|) = 1;
	undef $/;
}

Proc::Daemon::Init;

my $yh = new yahoo();

=comment
定义插入数组的缺省值.
keyword: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'yahoo'
=cut

our $h = {
	'source'    => $yh->{'dbh'}->quote(SURL),
	'createdby' => $yh->{'dbh'}->quote( $yh->get_os_stripname(__FILE__) ),
};

my $mech = WWW::Mechanize->new() or die;
$mech->timeout(20);

#####################################################
chdir();
sysopen( FIFO, NP_YAHOO, O_RDONLY ) or die "$!";
my $fh = new FileHandle( DHOME . "logs/yahoo.log", "w" ) or die "$!";
$fh->autoflush(1);

while (1) {
	my $php_input = <FIFO>;
	if ($php_input) {
		my $keyword = $php_input;
		print $fh $keyword . "\n";
		$keyword = decode( "utf-8", $keyword );
		$h->{'keyword'} = $yh->{'dbh'}->quote($keyword);

		$mech->get(SURL);
		$mech->success or die $mech->response->status_line;

		$mech->submit_form(
			form_id => 'sf',
			fields  => { p => $keyword }
		);
		$mech->success or die $mech->response->status_line;

		#$mech->save_content('/tmp/yh1.html');
		# undefined subroutune: print $mech-text();
		# $mech->dump_text();
		# $yh->write_file('yh1.html', $mech->content);

		# 保存查询的url, 上面有字符集, 查询数量等信息.
		$h->{'author'} = $yh->{'dbh'}->quote( $mech->uri()->as_string )
		  if ( $mech->uri );

		# 1.
		my $t = $yh->strip_result( $mech->content );

		# $yh->write_file('yh2.html', $t);

		my $aoh = $yh->parse_result($t);

		# $yh->write_file('yh3.html', $aoh);

		# yahoo竟然没有相关关键词推荐!!!
		my $sql = '';
		foreach my $p ( @{$aoh} ) {
			$h->{'url'}   = $yh->{'dbh'}->quote( $p->[0] );
			$h->{'title'} = $yh->{'dbh'}->quote( $p->[1] );
			$h->{'desc'}  = $yh->{'dbh'}->quote( $p->[2] );

 # 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
			$h->{'pubdate'} = $yh->{'dbh'}->quote( $yh->get_time('2') );

			$h->{'clicks'}  = $yh->generate_random();
			$h->{'likes'}   = $yh->generate_random(100);
			$h->{'guanzhu'} = $yh->generate_random(100);

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
			$yh->{'dbh'}->do($sql);
		}
	}
}

close(FIFO);
$yh->{'dbh'}->disconnect();
exit 6;

