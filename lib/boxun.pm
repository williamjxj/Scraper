package boxun;

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

sub strip_newslist {
	my ($self, $html) = @_;
	$html =~ m{
		#C0C0C0
		.*?
		</table>
		(.*?)		#列表
		#C0C0C0
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
    	.*?
    	</li>
    }sgix) {
        my ($href,$title) = ($1,$2);
        push (@{$aoh}, [$href,$title]);
    }
    return $aoh;
}

sub strip_detail {
	my ($self, $html) = @_;
	$html =~ m{
		id="Content"
		.*?>
		(.*?)	#正文
		<!--bodyend-->
	}sgix;
	return $1;
}

sub parse_detail {
	my ($self, $html) = @_;
    return unless $html;
    $html =~ m {
    	<center>
    	.*?
    	<b>
    	(.*?)	#标题
    	</b>
    	.*?
    	<small>
    	(.*?)	#博讯北京时间2012年12月19日 
    	</small>
    	.*?
		<!--bodystart-->
    	(.*?)	#正文
    	<p>
    	.*?
    }sgix;
	my ($title, $sd, $desc) = ($1, $2, $3);

	# Use of uninitialized value $desc in substitution (s///) at line 100,101,102,104.
	return unless $desc;

	$desc =~ s{<script.*?</script>}{}g;
	
	$sd =~ m {
		(.*?)		# 来源
		(\d.*)		# 时间
	}sgix;
	my ($source, $pubdate) = ($1, $2);
	
    return ($title, $pubdate, $desc, $source);
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
