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
use yahoo;
use constant SURL => q{http://hk.search.yahoo.com/};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode("utf-8", $ARGV[0]);

my $hk = new yahoo() or die $!;
my $h = {
	'keyword' => $hk->{'dbh'}->quote($keyword),
	'source' => $hk->{'dbh'}->quote(SURL),
	'createdby' => $hk->{'dbh'}->quote($hk->get_os_stripname(__FILE__)),
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
# $hk->write_file('yh1.html', $mech->content);

# 保存查询的url, 上面有字符集, 查询数量等信息.
$h->{'author'} = $hk->{'dbh'}->quote($mech->uri()->as_string) if($mech->uri);


my $t = $hk->strip_result( $mech->content );
# $hk->write_file('yh2.html', $t);


my $aoh = $hk->parse_result($t);
# $hk->write_file('yh3.html', $aoh);


# yahoo竟然没有相关关键词推荐!!!
my $sql = '';
foreach my $p (@{$aoh}) {
	$h->{'url'} = $hk->{'dbh'}->quote($p->[0]);
	$h->{'title'} = $hk->{'dbh'}->quote($p->[1]);
	$h->{'desc'} = $hk->{'dbh'}->quote($p->[2]);

	# 当前OS系统的时间, created 存放数据库系统的时间,两者不同.
	$h->{'pubdate'} = $hk->{'dbh'}->quote($hk->get_time('2'));

	$h->{'clicks'} = $hk->generate_random();
	$h->{'likes'} = $hk->generate_random(100);
	$h->{'guanzhu'} = $hk->generate_random(100);	

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
	$hk->{'dbh'}->do($sql);
}

$hk->{'dbh'}->disconnect();
exit 6;

