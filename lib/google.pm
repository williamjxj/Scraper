package google;

use config;
use common;
@ISA = qw(common);
use strict;
use FileHandle;
use Data::Dumper;
use constant CONTACTS => q{contexts};

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	bless $self, $type;
}

sub parse_page
{
    my ( $self, $html ) = @_;
    return unless $html;
	$html =~ m {
		Result\sPage:
		(?:.*?)
		<font\scolor="\#a90a08">
		(.*?)
		</font>
		(?:.*?)
		<a(?:.*?)href="(.*?)"
		(?:.*?)
		>
		(.*?)			# current page.
		</span>
    }sgix;
	my ($cur, $alink, $next_page) = ($1, $2, $3);
	$next_page =~ s/\<.*?>//g if ($next_page);
	return [ $cur, $alink, $next_page ];
}

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
				id=(?:nav|"nav")
		}sgix;
		$striped_html = $1;
		return $self->trim( $striped_html );
	}
}

sub parse_result
{
    my ($self, $html) = @_;
    my $aoh = [];

    while ($html =~ m {
        <li\sclass=(?:g|"g")>
        <h3(?:.*?)
		<a\s
		href="(.*?)"	#url
        (?:.*?)
		>
		(.*?)			#title
		</a>
		</h3>
        <div\sclass=(?:s|"s")>
        (.*?)			#content
		</li>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t1 =~ s/^\/url\?q=//  if($t1 =~ m/^\/url/);
		$t1 =~ s/\&sa=.*$//  if($t1 =~ m/\&sa=/);
		#$t1 =~ s/^.*\?q=//  if($t1 =~ m/^.*\?q=/);
		$t2 =~ s/\<em>//g if ($t2=~m/\<em>/);
		$t2 =~ s/\<\/em>//g if ($t2=~m/\<\/em>/);
		$t2 =~ s/\<b>\.+\<\/b>//s;
		$t3 =~ s/\<br>.*$//sg;
		$t3 =~ s/\<b>\.\.\.\<\/b>/.../sg;
		$t3 =~ s/\<.*?>//sg;
        push (@{$aoh}, [$t1,$t2,$t3]);
    }
    return $aoh;
}
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

sub trim
{
    my ($self, $str) = @_;
    return '' unless $str;

	$str =~ s/\r//g if ($str=~m/\r/);
	$str =~ s/\n//g if ($str=~m/\n/);
    $str =~ s/&nbsp;/ /g if ($str =~ m/&nbsp;/);
    $str =~ s/&amp;/&/g if ($str =~ m/&amp;/);
    $str =~ s/^\s+// if ($str =~ m/^\s/);
    $str =~ s/\s+$// if ($str =~ m/\s$/);
    return $str;
}

#####################

sub write_file
{
	my ($self, $file, $html) = @_;
	$file = '/tmp/' . $file;
	my $fh = FileHandle->new($file, "w");
	die unless (defined $fh);
	if(ref $html) {
		print $fh Dumper($html);
	}
	else {
		print $fh $html;
	}
	$fh->autoflush(1);
	$fh->close();
}
sub parse_item {
	my ($self, $html) = @_;
	my $aoh = [];
    $html =~ m {
        <h3\sclass=(?:"t"|t)
        (?:.*?)>
		<a
		(?:.*?)
		href="(.*?)"	#url
		(?:.*?)
		>
		(.*?)			#title
		</a>
		(?:.*?)
		<font\ssize=(?:"-1"|-1)>
        (.*)			#content
    }sgix;
    my ($t1,$t2,$t3) = ($1,$2,$3);
    push (@{$aoh}, $t1,$t2,$t3);
	return $aoh;
}
sub strip_tag
{
	my ($self, $str) = @_;
	return '' unless $str;

	$str =~ s/<(?:.*?)>//g if ($str=~m"<");
	$str =~ s/<\/.*?>//g if ($str=~m"</");
	$str =~ s/<script.*?>.*?<\/script>//sg if ($str=~"<script");
	return $str;
}

1;
