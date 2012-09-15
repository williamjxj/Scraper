#!/opt/lampp/bin/perl -w

use warnings;
use strict;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode encode);

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

our ( $mech, $mech1) = ( undef, undef );

our $bd = new common() or die $!;

my $h = {
	'category' => '',
	'cate_id' => 0,
	'item' => '',
	'item_id' => 0,
	'createdby' => $dbh->quote($bd->get_os_stripname(__FILE__)),
};

$mech = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech1 = WWW::Mechanize->new( autocheck => 0 ) or die;
$mech->timeout( 20 );
$mech1->timeout( 20 );

$mech->get( SEARCH_URL );
$mech->success or die $mech->response->status_line;
# print $mech->uri . "\n";

# 'fields'    => { wd => $keyword, rn => 100, ie=>"utf-8" }
$mech->submit_form(
    'form_name' => 'f',
	'fields'    => { wd => $keyword }
);
$mech->success or die $mech->response->status_line;

print $mech->content;

my $t = $bd->strip_result( $mech->content );
my $aoh = $bd->parse_result($t);

print Dumper($aoh);

exit;

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

	$garef = $bd->parse_url( $mech1->content );

	my ($html, $detail, $title, $sth);
	$html = $mech1->content;

	# after parse homepage of the website, search email/phone.
	$detail = $bd->get_detail( $html );

	print Dumper($detail);
	next if($detail eq '' );
	$detail = $dbh->quote($detail);
	
	$title = $dbh->quote($garef->[0] );
	$description = $dbh->quote($garef->[1]);
	$keywords = $dbh->quote($garef->[2] );

	my $rank = {};
	my $category = $dbh->quote($rank->[2]);
	my $item = $dbh->quote($rank->[0]);

	my $sql = qq{ insert into t_baidu
		(title,
		url,
		pubDate,
		source, 
		author, 
		category,
		cate_id,
		item,
		item_id,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubDate'},
		$h->{'source'}, 
		$h->{'author'},
		$category,
		$h->{'cate_id'},
		$item,
		$h->{'item_id'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)
	on duplicate key update
		content = $h->{'desc'},
		pubDate = $h->{'pubDate'}
	};
	$dbh->do($sql);

	undef( @{$garef} );
	$mech1->back;
}

$dbh->disconnect();
exit 8;

########################
sub strip_result {
	my ( $self, $html ) = @_;
	$html =~ m {
			<div\sid="container"
			(.*?)
			id="page">
	}sgix;
	return $1;
}

sub parse_result
{
    my ($self, $html) = @_;
    my $aoh = [];

    while ($html =~ m {
    	<table
		(?:.*?)
        class="(?:result-op|result)"
        (?:.*?)>
        <h3\sclass="t">
		<a(?".*?)
		href="(.*?)"	#url
		(?:.*?)
		>
		(.*?)			#title
		</a>
		(?:.*?)
		<(?:td\sclass="f"|font\ssize="-1")>
        (.*?)			#content
		</td>
		(?:.*?)
		</table>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
sub get_detail {
	my ( $self, $html ) = @_;
	return unless $html;
	my $detail = '';
    while ($html =~ m {
        <body>
        (.*)
        </body>
    }sgix) {
    	$detail = $1;
    	$detail =~ s/<script.*?>.*?<\/script>//sg;
    }
    return $detail;
}


sub parse_page
{
    my ( $self, $html ) = @_;
    return unless $html;
	$html =~ m {
		Result\sPage:
		(?:.*?)
		<font\scolor="\#a90a08">
		(.*?)
		</font>
		(?:.*?)
		<a(?:.*?)href="(.*?)"
		(?:.*?)
		>
		(.*?)			# current page.
		</span>
    }sgix;
	my ($cur, $alink, $next_page) = ($1, $2, $3);
	$next_page =~ s/\<.*?>//g if ($next_page);
	return [ $cur, $alink, $next_page ];
}
sub parse_next_page
{
   my ( $self, $html ) = @_;
    return unless $html;
    while (
        $html =~ m {
        id=(?:nav|"nav")
        (?:.*)
	<b>(.*?)</b>			# current page.
		(?:.*?)
        <td>
		(?:.*?)
		<a(?:.*?)\shref="(.*?)"
		(?:.*?)
		</span>
		(.*?)			# next page.
		(?:</a>|</td>)
    }sgix) {
		my ($cur_page, $alink, $next_page) = ($1, $2, $3);
		$cur_page =~ s/\<span.*?>//g;
		$cur_page =~ s/\<\/span>//g;
		$next_page =~ s/\<span.*?>//g;
		$next_page =~ s/\<\/span>//g;
        return [ $cur_page, $alink, $next_page ];
    }
    return;	
}

sub insert_contents
{
	
}
