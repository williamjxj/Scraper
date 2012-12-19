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
		C0C0C0
		.*?
		</table>
		(.*?)		#列表
		C0C0C0
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
    }sgix) {
        my ($href,$title) = ($1,$2);
        push (@{$aoh}, [$href,$title]);
    }
    return $aoh;
}

sub strip_detail {
	my ($self, $html) = @_;
	$html =~ m{
		'Content'
		.*?>
		(.*?)	#正文
		<!--bodyend-->
	}sgx;
	return $1;
}

sub parse_detail {
	my ($self, $html) = @_;
    return unless $html;
    $html =~ m {
    	<center>
    	(.*?)	#标题
    	<
    	.*?
    	<small>
    	(.*?)	#博讯北京时间2012年12月19日 
    	</small>
    	.*?
		<!--bodystart-->
    	(.*)	#正文
		(?:\[|$)
    }sgix;
	my ($title, $sd, $desc) = ($1, $2, $3);

	# Use of uninitialized value $desc in substitution (s///) at line 100,101,102,104.
	return unless $desc;

	$desc =~ s{<script.*?</script>}{}sg if $desc=~m/\<script/s;
	# $desc =~ s{<iframe.*?</iframe>}{}sg if $desc=~m/\<iframe/s;
	$desc =~ s{<img\ssrc=(.*?)\s}{<img\ssrc=http://boxun.com$1 }sgix  if($desc=~m/\<img/s);
	$desc =~ s{href=(.*?)(>|\s)}{href=http://boxun.com$1$2}sgix  if($desc=~m/\<a/s);
	
	$sd =~ s/\s.*$//; #remove space & thereafter.
	$sd =~ m {
		(.*?)
		(\d.*)
	}sgix;
	my ($source, $pubdate) = ($1, $2);

	$source =~ s/^\(// if $source=~m/^\(/;
	$source .= $pubdate if $source !~ m/\d/;

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
