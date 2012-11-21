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

sub strip_result {
	my ($self, $html) = @_;
}

sub parse_result {
    my ($self, $html) = @_;
    return unless $html;
    my $aoh = [];
    while ($html =~ m {
        <li\sclass=(?:g|"g")>
        (?:.*?)
        <h3\sclass=(?:r|"r")>
        (?:.*?)
		<a
		(?:.*?)
		href="(.*?)"	#1.url部分
        (?:.*?)
		>
		(.*?)			#2.标题部分
		</a>
		(?:.*?)
        <div\sclass=(?:s|"s")>
        (?:.*?)
        <cite>
        (.*?)			#3.source部分
        </cite>
        (?:.*?)
        <span\sclass="st">
        (.*?)			#4.content正文部分
        </span>
        (?:.*?)
		</li>
    }sgix) {
        my ($t1,$t2,$t3, $t4) = ($1,$2,$3,$4);
		$t1 =~ s/^\/url\?q=//  if($t1 =~ m/^\/url/);
		$t1 =~ s/\&sa=.*$//  if($t1 =~ m/\&sa=/);
		#$t1 =~ s/^.*\?q=//  if($t1 =~ m/^.*\?q=/);
		$t2 =~ s/\<em>//g if ($t2=~m/\<em>/);
		$t2 =~ s/\<\/em>//g if ($t2=~m/\<\/em>/);
		$t2 =~ s/\<b>\.+\<\/b>//s;
		$t4 =~ s/\<br>.*$//sg;
		$t4 =~ s/\<b>\.\.\.\<\/b>/.../sg;
		$t4 =~ s/\<.*?>//sg;
        push (@{$aoh}, [$t1,$t2,$t3,$t4]);
    }
    return $aoh;
}

sub strip_detail {
	my ($self, $html) = @_;
}

sub parse_detail {
	my ($self, $html) = @_;	
}

sub parse_next_page
{
    my ( $self, $html ) = @_;
    return unless $html;
    while (
        $html =~ m {
        id=(?:nav|"nav")
        (?:.*)
	<b>(.*?)</b>			# current page.
		(?:.*?)
        <td>
		(?:.*?)
		<a(?:.*?)\shref="(.*?)"
		(?:.*?)
		</span>
		(.*?)			# next page.
		(?:</a>|</td>)
    }sgix) {
		my ($cur_page, $alink, $next_page) = ($1, $2, $3);
		$cur_page =~ s/\<span.*?>//g;
		$cur_page =~ s/\<\/span>//g;
		$next_page =~ s/\<span.*?>//g;
		$next_page =~ s/\<\/span>//g;
        return [ $cur_page, $alink, $next_page ];
    }
    return;
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
