#! /cygdrive/c/Perl/bin/perl.exe

use lib qw(../lib/);
use craig_config;
use db;
use craig;

use warnings;
use strict;
use Data::Dumper;
use FileHandle;
use WWW::Mechanize;
use DBI;
use Getopt::Long;

local($|) = 1; 
undef $/;

#-----------------------------------
# 0. initialize:
#-----------------------------------
our ($num, $start_time, $end_time) = (0,0,0);
our ($start_url, $page_url, $todate) = (URL6, undef, INTERVAL_DATE);
our ($end_date, $today) = ('', []);
our ($mech, $db, $craig, $log) = (undef, undef);
my ($dbh, $sth);

$start_time = time;

my ($host, $user, $pass, $dsn) = (HOST, USER, PASS, DSN);
$dsn .= ":hostname=$host";
$db = new db($user, $pass, $dsn) or die;
$dbh = $db->{dbh};

$craig = new craig($db->{dbh}) or die;

$log = $craig->get_filename(__FILE__);
$craig->set_log($log);
$craig->write_log("\n[".$log."]: start at: [".localtime() . "].");

my ($city, $item) = (DEFAULT_CITY, 'housing');
my ($keywords,$email) =(undef,undef);
my ($first, $help, $version) = (undef, undef, undef);

usage() unless (GetOptions(
	'first' => \$first,
	'todate=s' => \$todate,
	'city=s' => \$city,
	'item=s' => \$item,
	'keywords=s' => \$keywords,
	'email=s' => \$email,
	'version=s' => \$version,
	'help|?' => \$help
));

$help && usage();

if ($first) {
	my $ca1 = $craig->select_ca_cities();
	foreach my $ca2 (@$ca1) {
		foreach my $ca3 (@{$ca2}) {
			print $ca3 . "\n";
		}
	}
	exit 1;
}
if ($version) {
	print <<EOF;

$0:  Version 2.0
EOF
	exit 2;
}

# date +'%a %d %b' -d "2 day ago"
if ($todate) {
	$end_date = $craig->get_end_date($todate);
}

if ($city && $item) {
	my ($r1, $r2) = ('', '');

	$r1 = $craig->select_city($city);
	die "No such city: <".$city.">, $0 quit." unless ($r1);

	$r2 = $craig->select_category($item);
	die "No such category: <".$item.">, $0 quit." unless ($r2);
	
	$start_url = $r1 . $r2 if ($city && $item);
	$craig->write_log("URL: <".$start_url.">.");
	print $start_url . "\n";
}
if ($keywords && $email) {
	$craig->select_keywords_email($keywords, $email);
}
elsif ($keywords) {
	$craig->select_keywords($keywords);
}
elsif ($email) {
	$craig->select_email($email);
}

$mech = WWW::Mechanize->new( autocheck => 0 );

$page_url = $start_url;

LOOP:
$mech->get($page_url);
$mech->success or die $mech->response->status_line; 
my $html = $mech->content;

# Only parse data before $end_date.
my $ht = $craig->parse_date($end_date, $html);
unless ($ht) {
	$dbh->disconnect();
	$end_time = time;
	$craig->write_log("$todate dates data: total [ " . ($end_time - $start_time) . " ] seconds used.\n");
	$craig->write_log( "There are total [ $num ] records was processed succesfully!\n");
	$craig->close_log();
	exit 6;
}

$page_url = $craig->parse_next_page($ht);
$page_url = $start_url .  $page_url if ($page_url);
# $craig->write_log($aoh);

my $aoh = $craig->parse_main($ht);


foreach my $t (@{$aoh})
{
	my $url = $t->[0];

	$num ++;
	$mech->follow_link(url => $url);
	$mech->success or next;

	my ($pdt,$pemail,$phone,$web,$relevant) = $craig->parse_detail($mech->content);
	if (defined $pemail) 
	{
		my ($t0, $t1, $t2, $t3, $t4, $t5) = @{$t};
		$t0 = $dbh->quote($t->[0]);
		$t1 = $dbh->quote($t->[1]);
		$t2 = $dbh->quote($t->[2]);
		$t3 = $dbh->quote($t->[3]);
		$t4 = $dbh->quote($t->[4]);
		$pdt = ' ' unless ($pdt);
		# phone
		$phone = $dbh->quote($phone);
		# web
		$web = $dbh->quote($web);
		$relevant = $dbh->quote($relevant);

		my $c1 = $dbh->quote($city); # st john's,NL
		$craig->write_log("No: ".(++$num)." -- [".$t0.", ".$t1.", ".$t2.", ".$t3.", ".$t4.", ".$pdt.", ".$pemail.", ".$phone.", ".$web.", ".$c1.", ".$item."], [".$relevant."]\n");

		$sth = $dbh->do(qq{ insert ignore into }.TOPIC.qq{
		(url,keywords,relevant,location,item_url,item,post_time,email,phone,
		web,city,category,date)
		values($t0,$t1,$relevant,$t2,$t3,$t4,'$pdt','$pemail',
		$phone, $web, $c1,'$item',now())});

	}
 
	$mech->back();
}

goto LOOP if ($page_url);


# $sth->finish();
$dbh->disconnect();

$end_time = time;
$craig->write_log("$todate days data: total [ " . ($end_time - $start_time) . " ] seconds used.\n");
$craig->write_log( "There are total [ $num ] records was processed succesfully!\n");
$craig->write_log("----------------------------------------------\n");
$craig->close_log();

exit 8;


sub usage
{
print <<HELP;
Uage:
      $0
     or:
      $0 -c city -i category
     or:
      $0 -t 3
     or:
      $0 -k keyword -e email
     or:
      $0 -h  [-v]
Description:
  -t from what date to download? default it's from 2 days before.
  -c city, which city to scrape?
  -i category/item, which category/item to scrape?
  -k search by keywords, what keyword to search?
  -e search by email, what email to search
  -h this help
  -v version

Description:
  -f first time to loop all city.
  -t from when to begin scraping? default is 2 days before.
  -c city to search
  -i category to search
  -k keywords to search
  -e email  to search
  -f logfile to search
  -h this help

Default Usage: $0 (e.g: $0 -h localhost -u craig -p -c vancouver -i housing -k 'php develper' -f 'vancouver'

HELP
exit 3;
}

