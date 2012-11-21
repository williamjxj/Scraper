package wenxuecity;

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
		class="pagenav
		(.*?)
		id="newslist"
	}sgix;
	return $1;	
}

sub parse_next_page
{
    my ( $self, $html ) = @_;
    return unless $html;

    $html =~ m {
		class="current"
		(?:.*?)
		href="(.*?)"	# next page link
		(?:.*?)
		>
		(.*?)			# next page.
		(?:</a>|</li>)
    }sgix;
	my ($alink, $next_page) = ($1, $2);
	$alink =~ s/^\s*//;
	$alink =~ s/\s*%//;
    #return [ $alink, $next_page ];
    return $alink;
}


sub strip_newslist {
	my ($self, $html) = @_;
	$html =~ m{
		id="newslist"
		(.*?)
		class="pagenav
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
    	.*?
    	>
    	(.*?)			# 标题
    	</a>
    	.*?
    	class="dateline">
    	(.*?)			#日期
    	</div>
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
		id="newswrapper"
		(.*?)
		id="comment"
	}sgix;
	return $1;
}

# $title, $source, $pubdate, $clicks, $desc
sub parse_detail {
	my ($self, $html) = @_;

    $html =~ m {
    	<h1
    	.*?>
    	(.*?)	#标题
    	</h1>
    	.*?
    	id="postmeta">
    	(.*?)	#来源，时间
    	</div>
    	.*?
    	id="countnum">
    	(.*?)	#阅读次数。
    	</span>
    	.*?
    	id="postbody"
    	.*?>
    	(.*)	#正文,贪婪匹配到最后的div
    	</div>
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
	
    return ($title, $source, $pubdate, $clicks, $desc);
}



## clean any expired %seen tags
sub clean {
	my $now = time;
	my %seen;
	for ( keys %seen ) {
		delete $seen{$_} if $seen{$_} < $now;
	}
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


=head1

sub test1 {
    my ( $self, $html ) = @_;
	$m->get("http://search.news.yahoo.com/search/news/options?p=");
	$m->field( "c", "news_photos" );
	$m->field( "p", "@keywords" );
	$m->field( "n", 100 );
	$m->click();
}

my @image_links = grep {
  $links[$_][0] =~ m{^http://story\.news\.yahoo\.com/} and $links[$_][1] eq "[IMG]";
} 0..$#links;

redo if $m->follow(qr{next \d});

=cut

1;
