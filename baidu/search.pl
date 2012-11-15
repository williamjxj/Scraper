#!/usr/bin/perl -w

use strict;
use warnings;
use utf8;
use encoding 'utf8';
#use lib qw(/home/williamjxj/perl5/lib/perl5/);
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode encode);

#use lib qq{$ENV{HOME}/scraper/lib/};
use lib qq{/home/williamjxj/scraper/lib/};
use config;
use db;
use common;

use constant SURL => 'http://www.baidu.com';

die "usage: $0 keyword" if ($#ARGV != 0);
our $keyword = $ARGV[0];
$keyword = decode("utf8", $keyword);

our $dbh = new db( USER, PASS, DSN.":hostname=".HOST );

our $bd = new common() or die $!;
$bd->{dbh} = $dbh;

my $h = {
	'keyword' => $dbh->quote($keyword),
	'source' => $dbh->quote(SURL),	
	'createdby' => $dbh->quote('baidu'),
};

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

# 'fields'    => { wd => $keyword, rn => 100, ie=>"utf-8" }
$mech->submit_form(
    'form_name' => 'f',
	'fields'    => { wd => $keyword }
);
$mech->success or die $mech->response->status_line;
#write_file('bd1.html', $mech->content);

$h->{'author'} = $dbh->quote($mech->uri()->as_string) if($mech->uri);

my $t = strip_result( $mech->content );
#write_file('bd2.html', $t);

my $aoh = parse_result($t);
#write_file('bd3.html', $aoh);
#print Dumper($aoh);

#保存baidu的相关搜索关键词.
my $kid = $bd->get_kid_by_keyword($keyword);
if($kid) {
	my ($rks, $html, $rkey, $rurl, $sql) = ([]);

	$html = strip_related_keywords($mech->content);

	$rks = get_related_keywords($html) if $html;

	foreach my $r (@{$rks}) {
		$rkey = $dbh->quote($r->[1]);
		$rurl = $dbh->quote(SURL . $r->[0]);
		$sql = qq{
			insert ignore into key_related(rk, kurl, kid, keyword, createdby, created)
			values(
				$rkey,
				$rurl,
				$kid,
				$h->{'keyword'},
				$h->{'createdby'},
				now()
			)
		};
		$dbh->do($sql);		
	}
}

foreach my $r (@{$aoh}) {

	my $p = parse_item($r);
	# print Dumper($p);
	next unless defined($p->[1]);

	$h->{'url'} = $dbh->quote($p->[0]);
	$h->{'title'} = $dbh->quote(strip_tag($p->[1]));
	$h->{'desc'} = $dbh->quote(strip_tag($p->[2]));

	$h->{'pubdate'} = $dbh->quote($bd->get_time('2'));

	$h->{'clicks'} = $bd->generate_random();
	$h->{'likes'} = $bd->generate_random(100);
	$h->{'guanzhu'} = $bd->generate_random(100);	

	my $sql = qq{  insert ignore into contents(
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
	$dbh->do($sql);

}

$dbh->disconnect();
exit 8;

########################
sub write_file
{
	my ($file, $html) = @_;
	$file = '/tmp/' . $file;
	my $fh = FileHandle->new($file, "w");
	die unless (defined $fh);
	if(ref $html) {
		print $fh Dumper($html);
	}
	else {
		print $fh $html;
	}
	$fh->autoflush(1);
	$fh->close();
}
sub strip_result {
	my ( $html ) = @_;
	$html =~ m {
			<div\sid="container">
			(.*?)
			<p\sid="page">
	}sgix;
	return $1;
}
sub parse_item {
	my $html = shift;
	my $aoh = [];
    $html =~ m {
        <h3\sclass=(?:"t"|t)
        (?:.*?)>
		<a
		(?:.*?)
		href="(.*?)"	#url
		(?:.*?)
		>
		(.*?)			#title
		</a>
		(?:.*?)
		<font\ssize=(?:"-1"|-1)>
        (.*)			#content
    }sgix;
    my ($t1,$t2,$t3) = ($1,$2,$3);
    push (@{$aoh}, $t1,$t2,$t3);
	return $aoh;
}
sub strip_tag
{
	my $str = shift;
	return '' unless $str;

	$str =~ s/<(?:.*?)>//g if ($str=~m"<");
	$str =~ s/<\/.*?>//g if ($str=~m"</");
	$str =~ s/<script.*?>.*?<\/script>//sg if ($str=~"<script");
	return $str;
}

sub parse_result
{
    my ($html) = @_;
    my $aoh = [];

    while ($html =~ m {
    	<table
		(?:.*?)
        class="(?:result-op|result)"
        (?:.*?)>
		<td\sclass=(?:"f"|f)
		(?:.*?)
		>
        (.*?)			#content
		</td>
		(?:.*?)
		</table>
    }sgix) {
       push (@{$aoh}, $1);
    }
    return $aoh;
}

# 相关搜索。
sub strip_related_keywords
{
	my ( $html ) = @_;
	$html =~ m{
		<div\sid=(?:"rs"|rs)>
		(?:.*?)
		<table
		(?:.*?)
		>
		(.*?)
		</table>
		.*?
		<div\sid=(?:"search"|search)>
	}six;
	return $1;
}

sub get_related_keywords
{
	my $html  = shift;
	return unless $html;
	my $aoh = [];
	
	while($html =~ m{
		<a
		(?:.*?)
		href="
		(.*?)		#链接地址
		">
		(.*?)		#关键词
		</a>
	}sgix) {
		my ($t1, $t2) = ($1, $2);
		push (@{$aoh}, [$t1, $t2]);
	}
	return $aoh;
}
