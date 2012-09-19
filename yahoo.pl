#!/opt/lampp/bin/perl -w

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use yahoo;

use constant SURL => q{http://search.yahoo.com/};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode("utf-8", $ARGV[0]);

our $dbh = new db( USER, PASS, DSN.":hostname=".HOST );

my $yh = new yahoo( $dbh );

=comment
定义插入数组的缺省值.
tag: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'yahoo'
=cut
my $h = {
	'tag' => $dbh->quote($keyword),
	'createdby' => $dbh->quote($yh->get_os_stripname(__FILE__)),
};

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

#num=100->10
# fields    => { q => $keyword, num => 10 }
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
$h->{'author'} = $dbh->quote($mech->uri()->as_string) if($mech->uri);

# 1. 
my $t = $yh->strip_result( $mech->content );
# $yh->write_file('yh2.html', $t);

my $aoh = $yh->parse_result($t);
# $yh->write_file('yh3.html', $aoh);


my ($html, $rks, $sql) = ('', []);

$html = $yh->strip_related_keywords($mech->content);

$rks = $yh->get_related_keywords($html) if $html;

#保存yahoo��的相关搜索关键词.
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
	$h->{'pubdate'} = $dbh->quote($yh->get_time('2'));
	$h->{'source'} = $dbh->quote('yahoo��索程序');

	$h{'clicks'} = $yh->generate_random();
	$h{'likes'} = $yh->generate_random(100);
	$h{'guanzhu'} = $yh->generate_random(100);	

	$sql = qq{ insert ignore into contexts(
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

