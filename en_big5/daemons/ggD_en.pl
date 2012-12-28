#!/usr/bin/perl

use warnings;
use strict;
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
use google;

use constant SURL => q{http://www.google.com};

use constant DHOME     => '/home/williamjxj/scraper/';
use constant GOOGLE => DHOME . '.google_en';

BEGIN {
	unless ( -p GOOGLE ) {
		if (   system( "mknod", GOOGLE, "p" )
			&& system( "mkfifo", GOOGLE ) )
		{
			die "mk{nod,fifo} GOOGLE failed";
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

our $dbh = new db( USER, PASS, DSN . ":hostname=" . HOST );

my $gg = new google($dbh);

my $h = {
	'source'    => $dbh->quote(SURL),
	'createdby' => $dbh->quote('google'),
};

#####################################################
chdir();
sysopen( FIFO, GOOGLE, O_RDONLY ) or die "$!";
my $fh = new FileHandle( DHOME . "logs/google_en.log", "w" ) or die "$!";
$fh->autoflush(1);

while (1) {
	my $php_input = <FIFO>;

	if ($php_input) {
		my $keyword = $php_input;
		print $fh $keyword . "\n";
		$keyword = decode( "utf8", $keyword );
		$h->{'keyword'} = $dbh->quote($keyword);

		my $mech = WWW::Mechanize->new( autocheck => 0 ) or die;
		$mech->timeout(20);

		$mech->get(SURL);
		$mech->success or die $mech->response->status_line;

		$mech->submit_form(
			form_name => 'f',
			fields    => { q => $keyword, ie => 'UTF-8', hl => 'zh-CN' }
		);
		$mech->success or die $mech->response->status_line;

		$h->{'author'} = $dbh->quote( $mech->uri()->as_string )
		  if ( $mech->uri );

		my $aoh = $gg->parse_result( $gg->strip_result( $mech->content ) );

		foreach my $p ( @{$aoh} ) {
			$h->{'url'}   = $dbh->quote( $p->[0] );
			$h->{'title'} = $dbh->quote( $p->[1] );
			$h->{'desc'}  = $dbh->quote( $p->[2] );

			$h->{'pubdate'} = $dbh->quote( $gg->get_time('2') );

			$h->{'clicks'}  = $gg->generate_random();
			$h->{'likes'}   = $gg->generate_random(100);
			$h->{'guanzhu'} = $gg->generate_random(100);

			my $sql = qq{ insert ignore into contents_1(
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
$dbh->disconnect();
exit 6;

