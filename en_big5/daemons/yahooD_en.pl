#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use encoding 'utf8';
use WWW::Mechanize;
use Data::Dumper;
use DBI;
use Encode qw(decode);

use Proc::Daemon;
use Fcntl;
use feature qw(say);
use FileHandle;

use lib qw(/home/williamjxj/scraper/lib/);
use config;
use db;
use yahoo;

use constant SURL     => q{http://search.yahoo.com/};
use constant DHOME    => '/home/williamjxj/scraper/';
use constant YAHOO => DHOME . '.yahoo_en';

BEGIN {
	unless ( -p YAHOO ) {
		if ( system( "mknod", YAHOO, "p" ) && system( "mkfifo", YAHOO ) )
		{
			die "mk{nod,fifo} YAHOO failed";
		}
	}
	$SIG{'INT'}  = 'IGNORE';
	$SIG{'QUIT'} = 'IGNORE';
	$SIG{'TERM'} = 'IGNORE';
	$SIG{'PIPE'} = 'IGNORE';
	$SIG{'CHLD'} = 'IGNORE';
	local ($|) = 1;
	undef $/;
}

Proc::Daemon::Init;

my $yh = new yahoo();

our $h = {
	'source'    => $yh->{'dbh'}->quote(SURL),
	'createdby' => $yh->{'dbh'}->quote( $yh->get_os_stripname(__FILE__) ),
};

#####################################################
chdir();
sysopen( FIFO, YAHOO, O_RDONLY ) or die "$!";
my $fh = new FileHandle( DHOME . "logs/yahoo_en.log", "w" ) or die "$!";
$fh->autoflush(1);

while (1) {
	my $php_input = <FIFO>;
	if ($php_input) {
		my $keyword = $php_input;
		print $fh $keyword . "\n";
		$keyword = decode( "utf8", $keyword );
		$h->{'keyword'} = $yh->{'dbh'}->quote($keyword);

		my $mech = WWW::Mechanize->new( autocheck=>0 ) or die $!;
		$mech->timeout(20);
		$mech->get(SURL);
		$mech->success or die $mech->response->status_line;

		$mech->submit_form(
			form_id => 'sf',
			fields  => { p => $keyword }
		);
		$mech->success or die $mech->response->status_line;

		$h->{'author'} = $yh->{'dbh'}->quote( $mech->uri()->as_string )
		  if ( $mech->uri );

		my $t = $yh->strip_result( $mech->content );

		my $aoh = $yh->parse_result($t);

		my $sql = '';
		foreach my $p ( @{$aoh} ) {
			$h->{'url'}   = $yh->{'dbh'}->quote( $p->[0] );
			$h->{'title'} = $yh->{'dbh'}->quote( $p->[1] );
			$h->{'desc'}  = $yh->{'dbh'}->quote( $p->[2] );

			$h->{'pubdate'} = $yh->{'dbh'}->quote( $yh->get_time('2') );

			$h->{'clicks'}  = $yh->generate_random();
			$h->{'likes'}   = $yh->generate_random(100);
			$h->{'guanzhu'} = $yh->generate_random(100);

			$sql = qq{ insert ignore into contents_1(
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
			$yh->{'dbh'}->do($sql);
			
			delete $h->{'desc'};
			delete $h->{'title'};
			delete $h->{'keyword'};
			delete $h->{'author'};
			delete $h->{'url'};
			delete $h->{'source'};
			delete $h->{'pubdate'};
		}
		undef $aoh;
		undef $mech;
	}
}

close(FIFO);
$yh->{'dbh'}->disconnect();
exit 6;

