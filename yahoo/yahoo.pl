#!/opt/lampp/bin/perl -w

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);

BEGIN{
	if ( $^O eq 'MSWin32' ) {
		use lib qw(../lib/);
	}
	else {
		use lib qw(/home/williamjxj/scraper/lib/);
	}
}
use config;
use db;
use yahoo;

use constant SURL => q{http://search.yahoo.com/};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode("utf-8", $ARGV[0]);

my $yh = new yahoo();

=comment
定义插入数组的缺省值.
keyword: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'yahoo'
=cut
my $h = {
	'keyword' => $yh->{'dbh'}->quote($keyword),
	'source' => $yh->{'dbh'}->quote(SURL),
	'createdby' => $yh->{'dbh'}->quote($yh->get_os_stripname(__FILE__)),
};

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_id => 'sf',
	fields    => { p => $keyword }
);
$mech->success or die $mech->response->status_line;
$mech->save_content('/tmp/yh1.html');
# undefined subroutune: print $mech-text();
# $mech->dump_text();
# $yh->write_file('yh1.html', $mech->content);

# 保存查询的url, 上面有字符集, 查询数量等信息.
$h->{'author'} = $yh->{'dbh'}->quote($mech->uri()->as_string) if($mech->uri);

# 1. 
my $t = $yh->strip_result( $mech->content );
# $yh->write_file('yh2.html', $t);

my $aoh = $yh->parse_result($t);
# $yh->write_file('yh3.html', $aoh);

# yahoo竟然没有相关关键词推荐!!!
my $sql = '';
foreach my $p (@{$aoh}) {
	$h->{'url'} = $yh->{'dbh'}->quote($p->[0]);
	$h->{'title'} = $yh->{'dbh'}->quote($p->[1]);
	$h->{'desc'} = $yh->{'dbh'}->quote($p->[2]);

	# 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
	$h->{'pubdate'} = $yh->{'dbh'}->quote($yh->get_time('2'));

	$h->{'clicks'} = $yh->generate_random();
	$h->{'likes'} = $yh->generate_random(100);
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

$yh->{'dbh'}->disconnect();
exit 6;

