#!/opt/lampp/bin/perl -w

use warnings;
use strict;
#use utf8;
#use encoding 'utf8';
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

my $gpm = new google( $dbh );

my $h = {
	'cate_id' => 0,
	'iid' => 0,
	'createdby' => $dbh->quote('google_' . $gpm->get_os_stripname(__FILE__)),
};

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

#num=100->10
$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, num => 20 }
);
$mech->success or die $mech->response->status_line;
$h->{'author'} = $dbh->quote($mech->uri()->as_string) if($mech->uri);
$gpm->write_file('gg1.html', $mech->content);

my $t = $gpm->strip_result( $mech->content );
$gpm->write_file('gg2.html', $t);

my $aoh = $gpm->parse_result($t);
$gpm->write_file('gg3.html', $aoh);

foreach my $p (@{$aoh}) {

	$h->{'url'} = $dbh->quote($p->[0]);
	$h->{'linkname'} = $dbh->quote($p->[1]);
	$h->{'desc'} = $dbh->quote($p->[2]);

	$h->{'date'} = $dbh->quote($gpm->get_time('2'));
	$h->{'tag'} = $dbh->quote($keyword);
	$h->{'source'} = $dbh->quote('google搜索程序');

	my $sql = qq{ insert ignore into contexts
		(linkname,
		url,
		pubdate,
		tags,
		source,
		author,
		cate_id,
		iid,
		createdby,
		created,
		content
	) values(
		$h->{'linkname'},
		$h->{'url'},
		$h->{'date'},
		$h->{'tag'},
		$h->{'source'},
		$h->{'author'},
		$h->{'cate_id'},
		$h->{'iid'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)};
	$dbh->do($sql);
}

$dbh->disconnect();
exit 6;

