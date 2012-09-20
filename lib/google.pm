package google;

use config;
use common;
@ISA = qw(common);
use strict;
use FileHandle;
use Data::Dumper;

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	bless $self, $type;
}

# 第一步，提取有用部分的信息 。
sub strip_result {
	my ( $self, $html ) = @_;
	my $striped_html = undef;
	
	$html =~ m {
			<div\sid=(?:ires|"ires")
			(.*?)
			id=(?:nav|"nav")
	}sgix;
	$striped_html = $1;
	
	if ($striped_html) {
		return $self->trim( $striped_html );
	}
	else {
		$html =~ m {
				id=(?:rso|"rso")
				(.*?)
				id=(?:bottomads|"bottomads"|nav|"nav")
		}sgix;
		$striped_html = $1;
		return $self->trim( $striped_html );
	}
}

# 第二步，解析。
sub parse_result
{
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

# 相关搜索。
sub strip_related_keywords
{
	my ( $self, $html ) = @_;
	return $html;
}
sub get_related_keywords
{
	my ( $self, $html ) = @_;
	return [];
}

# google.pl 部分。
sub get_detail {
	my ( $self, $html ) = @_;
	return unless $html;
	my $detail = '';
    while ($html =~ m {
        <body>
        (.*)
        </body>
    }sgix) {
    	$detail = $1;
    	$detail =~ s/<script.*?>.*?<\/script>//sg;
    }
    return $detail;
}

sub parse_url
{
	my ( $self, $html ) = @_;
	return unless $html;

	my $aref = [];
	my ($title, $description, $keywords);

	if ($html =~ m{
		<title>
		(.*?)
		</title>
	}sgix) { 
		$title = $self->trim($1);
	}

	if ($html =~ m{
		<meta\s
		(?:.*?)
		name="keywords"
		(?:.*?)
		content="(.*?)"
		(?:.*?)
		(?:>|\/>)
	}sgix) {
		$keywords = $self->trim($1);
	}

	if ($html =~ m{
		<meta\s
		(?:.*?)
		name="description"
		(?:.*?)
		content="(.*?)"
		(?:.*?)
		(?:>|\/>)
	}sgix) {
		$description = $self->trim($1);
	}

	push (@{$aref}, $title, $description, $keywords);
	return $aref;
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

1;
