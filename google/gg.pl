#!/opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use google;

use constant SURL => q{http://www.google.com};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode("utf-8", $ARGV[0]);

our $dbh = new db( USER, PASS, DSN.":hostname=".HOST );

my $gg = new google( $dbh );

=comment
定义插入数组的缺省值.
tag: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'google'
=cut
my $h = {
	'tag' => $dbh->quote($keyword);
	'clicks' => $gg->generate_random();
	'likes' => $gg->generate_random(100);
	'guanzhu' => $gg->generate_random(100);	
	'createdby' => $dbh->quote('google_' . $gg->get_os_stripname(__FILE__)),
};

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

#num=100->10
# fields    => { q => $keyword, num => 10 }
$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, ie=>'UTF-8', hl=>'zh-CN' }
);
$mech->success or die $mech->response->status_line;
#$mech->save_content('/tmp/gg1.html');
# $gg->write_file('gg1.html', $mech->content);

# 保存查询的url, 上面有字符集, 查询数量等信息.
$h->{'author'} = $dbh->quote($mech->uri()->as_string) if($mech->uri);

# 1. 
my $t = $gg->strip_result( $mech->content );
# $gg->write_file('gg2.html', $t);

my $aoh = $gg->parse_result($t);
# $gg->write_file('gg3.html', $aoh);


my $html = $gg->strip_related_keywords($mech->content);

my $rks = $yh->get_related_keywords($html);

#保存google中的相关搜索关键词.
foreach my $r (@{$rks}) {
	$sql = qq{
		insert ignore into key_related(rk, kid, keyword, created)
		values(
		$r,
		$h->{'tag'},
		now()
	)};
	$dbh->do($sql);		
}

foreach my $p (@{$aoh}) {
	$h->{'url'} = $dbh->quote($p->[0]);
	$h->{'linkname'} = $dbh->quote($p->[1]);
	$h->{'desc'} = $dbh->quote($p->[2]);

	# 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
	$h->{'pubdate'} = $dbh->quote($gg->get_time('2'));
	$h->{'source'} = $dbh->quote('google搜索程序');

	my $sql = qq{ insert ignore into contents(
		linkname,
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
		$h->{'linkname'},
		$h->{'url'},
		$h->{'author'},
		$h->{'source'},		
		$h->{'pubdate'},
		$h->{'tag'},
		$h->{'clicks'},
		$h->{'likes'},
		$h->{'guanzhu'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)};
	$dbh->do($sql);
}

$dbh->disconnect();
exit 6;

