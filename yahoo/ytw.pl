#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);
use CGI qw(:standard);

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use yahoo;
use constant SURL => q{http://tw.search.yahoo.com/};

our $keyword;
if ($#ARGV == 0) {
	$keyword = decode("utf8", $ARGV[0]);
}
else {
	my $q = CGI->new;
	if (defined($q->param('q'))) {
		$keyword = $q->param('q');
		Encode::_utf8_on($keyword);	
	}
}
else {
	die "usage: $0 keyword";	
}

my $tw = new yahoo();

my $h = {
	'keyword' => $tw->{'dbh'}->quote($keyword),
	'source' => $tw->{'dbh'}->quote(SURL),
	'createdby' => $tw->{'dbh'}->quote($tw->get_os_stripname(__FILE__)),
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

# 保存查询的url, 上面有字符集, 查询数量等信息.
$h->{'author'} = $tw->{'dbh'}->quote($mech->uri()->as_string) if($mech->uri);

my $t = $tw->strip_result( $mech->content );

my $aoh = $tw->parse_result($t);

# yahoo竟然没有相关关键词推荐!!!
my $sql = '';
foreach my $p (@{$aoh}) {
	$h->{'url'} = $tw->{'dbh'}->quote($p->[0]);
	$h->{'title'} = $tw->{'dbh'}->quote($p->[1]);
	$h->{'desc'} = $tw->{'dbh'}->quote($p->[2]);

	# 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
	$h->{'pubdate'} = $tw->{'dbh'}->quote($tw->get_time('2'));

	$h->{'clicks'} = $tw->generate_random();
	$h->{'likes'} = $tw->generate_random(100);
	$h->{'guanzhu'} = $tw->generate_random(100);	

	$sql = qq{ insert ignore into } . CONTENTS_1 . qq{(
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
	$tw->{'dbh'}->do($sql);
}

$tw->{'dbh'}->disconnect();
exit 6;

