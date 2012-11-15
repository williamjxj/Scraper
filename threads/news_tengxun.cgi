#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'utf-8';
use encoding 'gb2312';
#use encoding "euc-cn";
use WWW::Mechanize;
use CGI qw(:standard);
use JSON;
use Encode;

binmode(STDOUT, ":utf8");

use constant SURL => q{http://news.soso.com/};

print header(-charset=>'utf-8');

my $q = CGI->new;

my $keyword = $q->param('q');

Encode::_utf8_on($keyword);
# yes: with or without use utf8;
#print $keyword; exit;

#$keyword = Encode::encode("gb2312", "$keyword");
#$keyword = encode("gb2312", decode("euc-cn", "$keyword"));
#$keyword = encode("euc-cn", $keyword);

# the UTF8 flag is on.
# $keyword = decode("gb2312", $keyword);

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
  form_name => 'flpage',
  fields    => { 
    ty => 'c',
    pid=>'n.home.result',
    w => "王波"
  }
);
$mech->success or die $mech->response->status_line;

<<<<<<< HEAD
=comment
my $fh = FileHandle->new("../html/t3.html", "w" );
#binmode($fh, ":encoding(utf8)");
binmode($fh, ":utf8");
print $fh $mech->content;
$fh->autoflush(1);
$fh->close();
=cut
=======
>>>>>>> 1c8a5229b671083a50c4c64a3be600a17d82604b

my $html = strip_result( $mech->content );

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 7;

###########################

sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <div\sid="result"
      .*?
      <ol.*?>
      (.*?) #soso用ol->li来划分每条记录
      </ol>
  }six;
  return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
  while ($html =~ m {
    <li
    .*?
    href="
    (.*?) #1.链接地址
    "
    (?:.*?)
    >
    (.*?) #2.标题
        </a>
        (?:.*?)
        </h3>
        (.*?) #3.正文
        </li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t3 =~ s/<div.*?<\/div>//gi;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
