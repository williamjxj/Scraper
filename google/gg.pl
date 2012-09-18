#!/opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode encode);

use lib qw(../lib/);
use config;
use db;
use google;

use constant SURL => q{http://www.google.com};

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = decode($ARGV[0], $ARGV[0]);

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
# print $mech->uri . "\n";

$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, num => 100 }
);
$mech->success or die $mech->response->status_line;

#write_file('gg1.html', $mech->content);
my $t = strip_result( $mech->content );
#write_file('gg2.html', $t);

my $aoh = parse_result($t);
#write_file('gg3.html', $aoh);
#print Dumper($aoh);

foreach my $r (@{$aoh}) {

	my $p = parse_item($r);
	# print Dumper($p);
	next unless defined($p->[1]);

	$h->{'url'} = $dbh->quote($p->[0]);
	$h->{'linkname'} = $dbh->quote(strip_tag($p->[1]));
	$h->{'desc'} = $dbh->quote(strip_tag($p->[2]));

	$h->{'date'} = $dbh->quote($gpm->get_time('2'));
	$h->{'tag'} = $dbh->quote($keyword);
	$h->{'source'} = $dbh->quote('google搜索程序');
	#$h->{'source'} = $dbh->quote($keyword);

	my $sql = qq{ insert ignore into contents
		(linkname,
		url,
		pubdate,
		tags,
		source,
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

