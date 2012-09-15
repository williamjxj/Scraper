#!/opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode encode);
use FileHandle;

#use lib qq{$ENV{HOME}/scraper/lib/};
use lib qq{/home/williamjxj/scraper/lib/};
use config;
use db;
use common;

use constant SEARCH_URL => 'http://www.baidu.com';

die "usage: $0 keyword" if ($#ARGV != 0);

our $keyword = $ARGV[0];

$keyword = decode("utf-8", $keyword);

my ( $host, $user, $pass, $dsn ) = ( HOST, USER, PASS, DSN );
$dsn .= ":hostname=$host";

our $dbh = new db( $user, $pass, $dsn );

my @blacklist = ('google', 'wikipedia');

our $bd = new common() or die $!;

my $h = {
	'cate_id' => 0;
	'iid' => 0,
	'createdby' => $dbh->quote('真 - ' . $bd->get_os_stripname(__FILE__)),
};

my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );

$mech->get( SEARCH_URL );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

# 'fields'    => { wd => $keyword, rn => 100, ie=>"utf-8" }
$mech->submit_form(
    'form_name' => 'f',
	'fields'    => { wd => $keyword }
);
$mech->success or die $mech->response->status_line;
#write_file('bd1.html', $mech->content);

my $t = strip_result( $mech->content );
#write_file('bd2.html', $t);

my $aoh = parse_result($t);
#write_file('bd3.html', $aoh);
#print Dumper($aoh);

foreach my $r (@{$aoh}) {

	my $p = parse_item($r);
	# print Dumper($p);
	next unless defined($p->[1]);

	$h->{'url'} = $dbh->quote($p->[0]);
	$h->{'linkname'} = $dbh->quote(strip_tag($p->[1]));
	$h->{'desc'} = $dbh->quote(strip_tag($p->[2]));

	$h->{'date'} = $dbh->quote($bd->get_time('2'));
	$h->{'tag'} = $dbh->quote($keyword);
	$h->{'source'} = $dbh->quote('真真真');

	my $sql = qq{ insert ignore into search
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
