package soso;

use config;
use common;
@ISA = qw(common);
use strict;
our ( $sth );

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	bless $self, $type;
}

# use for yy.pl. yahoo.com can pagnation, google.com can't.
sub strip_result
{
	my ( $self, $html ) = @_;
	$html =~ m {
			<div\sid="result"
			.*?
			<ol\s*>
			(.*?)	#soso用ol->li来划分每条记录
			</ol>
	}six;
	return $1;
}

sub parse_result
{
    my ( $self, $html ) = @_;
    return unless $html;
    my $aoh = [];    
	while ($html =~ m {
		<li
		.*?
		href="
		(.*?)	#1.链接地址
		"
		(?:.*?)
		>
		(.*?)	#2.标题
        </a>
        (?:.*?)
        <p\sclass="ds">
        (.*?)	#3.正文
        </p>
        (?:.*?)
        <cite>
        (.*?)	#4.日期和网址
        </cite>
    }sgix) {
        my ($t1,$t2,$t3,$t4) = ($1,$2,$3,$4);
        my @url_date = $t4 =~ m/(.*?)(?:\s|-|\.{1,3})(.*)/;
        push (@{$aoh}, [$t1,$t2,$t3,$url_date[0], $url_date[1]]);
    }
    return $aoh;
}


# 相关搜索。
sub strip_related_keywords
{
	my ( $self, $html ) = @_;
	$html =~ m{
		<div
		(?:.*?)
		id="rel"
		.*?
		>
		(.*?)
		<div\sid="bSearch"
	}six;
	return $1;
}
sub get_related_keywords
{
	my ( $self, $html ) = @_;
	return unless $html;
	my $aoh;
	
	while($html =~ m{
		<td
		(?:.*?)
		<a\shref="
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

sub get_kid_by_keyword
{
	my ($self, $keyword) = @_;
	$sth = $self->{dbh}->prepare(qq{ select kid from keywords where keyword = ? });
	$sth->execute($keyword);
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return defined $row[0] ? $row[0] : 0;
}

1;
