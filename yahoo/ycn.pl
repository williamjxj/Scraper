#!/usr/bin/perl -w

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
use yahoo;

use constant SURL => q{http://cn.search.yahoo.com/};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode("utf8", $ARGV[0]);

my $cn = new yahoo();
my $h = {
	'keyword' => $cn->{'dbh'}->quote($keyword),
	'source' => $cn->{'dbh'}->quote(SURL),
	'createdby' => $cn->{'dbh'}->quote($cn->get_os_stripname(__FILE__)),
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
#$mech->save_content('/tmp/yh1.html');
# undefined subroutune: print $mech-text();
# $mech->dump_text();
# $cn->write_file('yh1.html', $mech->content);

# 保存查询的url, 上面有字符集, 查询数量等信息.
$h->{'author'} = $cn->{'dbh'}->quote($mech->uri()->as_string) if($mech->uri);

# 1. 
my $t = $cn->strip_result( $mech->content );
# $cn->write_file('yh2.html', $t);

my $aoh = $cn->parse_result($t);
# $cn->write_file('yh3.html', $aoh);

# yahoo竟然没有相关关键词推荐!!!
my $sql = '';
foreach my $p (@{$aoh}) {
	$h->{'url'} = $cn->{'dbh'}->quote($p->[0]);
	$h->{'title'} = $cn->{'dbh'}->quote($p->[1]);
	$h->{'desc'} = $cn->{'dbh'}->quote($p->[2]);

	# 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
	$h->{'pubdate'} = $cn->{'dbh'}->quote($cn->get_time('2'));

	$h->{'clicks'} = $cn->generate_random();
	$h->{'likes'} = $cn->generate_random(100);
	$h->{'guanzhu'} = $cn->generate_random(100);	

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
	$cn->{'dbh'}->do($sql);
}

$cn->{'dbh'}->disconnect();
exit 6;

