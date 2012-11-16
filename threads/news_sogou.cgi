#!/usr/bin/perl

use strict;
use warnings;
#use utf8;
#use encoding 'euc-cn', STDIN => 'euc-cn', STDOUT => 'euc-cn';
use WWW::Mechanize;
use CGI qw/:standard/;
use JSON;
use Encode;
use Data::Dumper;

#binmode(STDIN, ":encoding(utf8)");
binmode STDOUT, ":utf8";

use constant SURL => q{http://news.sogou.com/};

print header(-charset=>'utf-8');

my $q = CGI->new;
my $keyword = $q->param('q');

#Encode::_utf8_on($keyword);

#$keyword = decode("utf8", "$keyword");
#Encode::from_to($keyword, 'gb2312', 'utf8');

$keyword = encode("euc-cn", $keyword);
#Encode::from_to($keyword, 'utf8', 'euc-cn');

my $mech = WWW::Mechanize->new( ) or die;
$mech->timeout( 20 );

#print $keyword; exit;

$mech->get( SURL );
$mech->success or die $mech->response->status_line;

$mech->submit_form(
    form_name => 'searchForm',
    fields    => {
		query => $keyword,
		p => '42040301',
		mode => 1
	}
);
$mech->success or die $mech->response->status_line;

print $mech->content;

exit;

#my $html = Encode::decode("utf8", $mech->content);
#$html = strip_result($html);
my $html = strip_result($mech->content);

=comment
my $fh = FileHandle->new('../html/t2.html', "w" );
binmode $fh, ':utf8';
print $fh $mech->content;
$fh->autoflush(1);
$fh->close();
=cut

my $aoh = parse_result($html);

my $json = JSON->new->allow_nonref;

print $json->encode($aoh);

exit 8;

###########################

sub strip_result
{
  my ( $html ) = @_;
  $html =~ m {
      <div\sclass="results"
	  .*?
	  >
      (.*?) #soso用ol->li来划分每条记录
      <table\sclass="hint"
  }six;
  return $1;
}

sub parse_result
{
    my ( $html ) = @_;
    return unless $html;
    my $aoh = [];    
  while ($html =~ m {
    class="pt"
    .*?
    href="
    (.*?) #1.链接地址
    "
    (?:.*?)
    >
    (.*?) #2.标题
        </a>
        (?:.*?)
        <div\sclass="ft">
        (.*?) #3.正文
        </div>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t3 =~ s/<a.*?<\/a>//ig;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
