#!/usr/bin/perl -w
##! /cygdrive/c/Perl/bin/perl.exe -w
#和gg.pl不同的是, 本文件从命令行执行,而不是从php进行调用.
# 没有输入'查询关键词'参数.
=comment
定义插入数组的缺省值.
tag: 关键词
clicks: 总共点击的次数, 0-1000
likes: 欣赏此文, 0-100
guanzhu: 关注此文, 0-100
created: 'google'
source:'google搜索程序'
=cut

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use FileHandle;
use Getopt::Long;

#如何将绝对路径改为相对的, for 移植 purpose?
use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use google;

use constant SURL => q{http://www.google.com};
use constant KEYFILE => q{./keywords.txt};

BEGIN
{
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	$ENV{'PATH'} = '/usr/bin/:/bin/:.';
	#好像不起作用.
	$ENV{'HOME'} = '/home/williamjxj/scraper/';
	local ($|) = 1;
	undef $/;
}

our ( $start_time, $end_time ) = ( 0, 0 );
$start_time = time;

# 2 mech are created, 1 for google, 1 for detail website.
our ( $mech, $mech1) = ( undef, undef );

my @blacklist = ('google', 'wikipedia');
my $dbh = new db( USER, PASS, DSN.":hostname=".HOST );
my $gpm = new google( $dbh );

my $log = $gpm->get_filename(__FILE__);
$gpm->set_log($log);
$gpm->write_log( "[" . $log . "]: start at: [" . localtime() . "]." );

my ( $html, $detail, $web ) = ( '', '', undef );
my ( $all_links, $url ) = ( [], SURL );
my ( $keyword, $kfile, $debug ) = ( undef, undef, 0 );
my ( $page_url, $cate_id ) = ('', 3);


$mech = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die $!;
$mech->timeout( 20 );
$mech1->timeout( 20 );

GetOptions(
	'web=s' => \$web,
	'keyword=s' => \$keyword,
	'debug' => \$debug,
);

# for test purpose
if ($web) {
	$mech->get( $web );
	$mech->success or die $mech->response->status_line;
	$detail = $gpm->get_detail( $mech->content );
	print Dumper( $detail );
	exit 1;
}

$keyword = '中国食品';
# read keywords.txt first line (without ^#).
unless ($keyword) {
	local ($/) = "\n";
	$kfile = new FileHandle(KEYFILE, 'r') or die $!;
	my @lines = <$kfile>;
	foreach my $line (@lines) {
		chomp($line);
		if ($line !~ m/^#/) {
			$keyword = $line;
			last;
		}
	}
	$kfile->close;
	die unless ($keyword);
}
$keyword = '中国食品' unless (defined $keyword && $keyword);


$mech->get( $url );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

$mech->submit_form(
    form_name => 'f',
	fields    => { q => $keyword, num => 100 }
);
$mech->success or die $mech->response->status_line;

my $paref = $gpm->parse_next_page( $mech->content );
print Dumper( $paref );
$page_url = $paref->[1];

# very imporant.
$page_url =~ s/\&amp;/\&/g if ($page_url=~m/&amp;/);
# $page_url =~ s/search\?/#/;
$page_url = $url . $page_url;

my $garef = [];
my ($description, $keywords, $title, $summary, $email, $phone, $fax, $link, $zip);

LOOP:

$mech->get( $page_url );
$mech->success or die $mech->response->status_line;

my $t = $gpm->strip_result( $mech->content );
my $aoh = $gpm->parse_result($t);
#print Dumper($aoh);

foreach my $r (@{$aoh}) {

	$link = $r->[0];
	$summary = $r->[1] . ': ' . $r->[2];
	$summary = $dbh->quote( $summary );
	print "-------------------------\n";
	print $link . "\n";

	if (grep{ $link =~ m{$_}i } @blacklist) {
		next;
	}

	$mech1->get( $link );
	$mech1->success or next;

	$garef = $gpm->parse_url( $mech1->content );
	# print Dumper( $garef );

	$html = $mech1->content;

	# after parse homepage of the website, search email/phone.
	$detail = $gpm->get_detail( $html );

	print Dumper($detail);
	next if($detail eq '' );
	$detail = $dbh->quote($detail);
	
	$title = $dbh->quote($garef->[0] );
	$description = $dbh->quote($garef->[1]);
	$keywords = $dbh->quote($garef->[2] );

	$dbh->do( qq{ insert ignore into foods
		(google_keywords, meta_description, meta_keywords, title, url, summary, fdate, cate_id, detail) 
		values( '$keyword', $description, $keywords, $title, '$link', $summary, now(), $cate_id, $detail)
	});

	undef( @{$garef} );
	$mech1->back;
}

$dbh->disconnect();

$end_time = time;
$gpm->write_log( "Total days' data: [ " . ( $end_time - $start_time ) . " ] seconds used.\n" );
$gpm->close_log();

exit 6;

