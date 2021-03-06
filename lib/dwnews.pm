package dwnews;

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
}

sub parse_next_page
{
    my ( $self, $html ) = @_;
}

sub strip_newslist {
	my ($self, $html) = @_;
	$html =~ m{
		class="newslist"
		.*?
		<ul>
		(.*?)
		</ul>
	}sgix;
	# 有很多注释掉的内容，要先除去，再解析。
	my $l = $1;
	$l =~ s{<!--.*?-->}{}sg;
	return $l;
}

sub parse_newslist {
    my ($self, $html) = @_;
    return unless $html;
    my $aoh = [];
    while ($html =~ m {
    	<li
    	.*?
    	<span>
    	(.*?)			#日期
    	</span>
    	.*?
    	href="(.*?)"	#链接
    	.*?>
    	(.*?)			# 标题
    	</a>
    	.*?
    	</li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}

sub strip_detail {
	my ($self, $html) = @_;
	$html =~ m{
		class="newsview"
		(.*?)
		class="(?:pagenum|mzsm)
	}sgix;
	return $1;
}

# $title, $source, $pubdate, $clicks, $desc
sub parse_detail {
	my ($self, $html) = @_;
	return unless $html;
    $html =~ m {
    	<h1>
    	(.*?)
    	</h1>
    	.*?
    	<span>
    	(.*?)	#来源，时间
    	</span>
    	.*?
    	id="Zoom"
    	.*?>
    	(.*)	#正文,贪婪匹配到最后的div
    	</div>
    }sgix;
	my ($title, $pubdate, $desc) = ($1, $2, $self->trim($3));
	$pubdate =~ s/.*a>//s;
	$pubdate =~ s{</span>}{}s;

	$desc =~ s/<!--.*?-->//s;
	$desc =~ s{<script.*?</script>}{}s;
	if($desc =~ m/id="adverid"/) {
		$desc =~ s{<div.*?id="adverid".*?</div>}{}s;
	}
	if($desc =~ m/class="xgzt"/) {
		$desc =~ s{<div\sclass="xgzt".*</ul>\s*</div>\s*</div>}{}s;
	}
	
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
