package liuyuan;

use config;
use common;
@ISA = qw(common);
use strict;

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	bless $self, $type;
}

sub strip_pagenav {
	my ($self, $html) = @_;
	$html =~ m{
	}sgix;
}

sub parse_next_page
{
    my ( $self, $html ) = @_;
    return unless $html;

    $html =~ m {
    }sgix;
}


sub strip_newslist {
	my ($self, $html) = @_;
	$html =~ m{
		class=(dc_bar|"dc_bar")
		.*?
		class=(dc_bar|"dc_bar")
		.*?>
		(.*?)		#列表
		<table
	}sgix;
	return $1;
}

sub parse_newslist {
    my ($self, $html) = @_;
    return unless $html;
    my $aoh = [];
    while ($html =~ m {
    	<li>
    	.*?
    	href="(.*?)"	#链接
    	.*?>
    	(.*?)		#标题
    	</a>
    	(.*?)		#来源
    	<i>
    	(.*?)		#日期
    	</i>
    	(.*?)		#阅读次数
    	(?:</li>|<ul>|</ul)
    }sgix) {
        my ($href,$title,$source,$created) = ($1,$2,$3,$4,$5);
        my ($clicks) = ($5 =~ m/(\d+)/s);
        
        push (@{$aoh}, [$href,$title,$source,$created,$clicks]);
    }
    return $aoh;
}

sub strip_detail {
	my ($self, $html) = @_;
	$html =~ m{
		class="td3"
		.*?>
		(.*?)	#正文
		<td
	}sgix;
	return $1;
}

# $title, $source, $pubdate, $clicks, $desc
# $title, $pubdate, $desc 
sub parse_detail {
	my ($self, $html) = @_;

    $html =~ m {
    	<h2
    	.*?>
    	(.*?)	#标题
    	</h2>
    	(.*?)	#</center>新闻来源: 纽约时报 于November 21, 2012 02:05:22 
    	<span
    	.*?
    	(.*?)	#正文
    	<center>
    }sgix;
	my ($title, $sd, $clicks, $desc) = ($1, $2, $3, $4);

	$sd =~ m {
		author">
		(.*?)		# 来源
		</span>
		.*?
		itemprop="datePublished"
		.*?
		>
		(.*?)		# 时间
		</time>
	}sgix;
	my ($source, $pubdate) = ($1, $2);
	
    return ($title, $pubdate, $desc);
}


sub get_end_date {
	my ( $self, $todate ) = @_;
	my $sth =
	$self->{dbh}->prepare( qq{ select date_format(date_sub(now(), interval } . $todate . qq{ day), '%Y-%m-%d' ) } );
	$sth->execute();
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

1;
