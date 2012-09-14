package google;

use config;
use common;
@ISA = qw(common);
use strict;
our ( $sth );

use constant CONTACTS => q{contexts};

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'food';
	$self->{uniq_links} = [];
	bless $self, $type;
}

# mailto:sales@rkymtn.com?subject=Sales%20Request
# return email, phone, fax, zip.
sub get_detail1 {
	my ( $self, $html ) = @_;
	return unless $html;

	my $detail = [];
	# default: undef
	my ($email, $phone, $fax, $zip);

	$email = $self->get_email( $html );
	$phone = $self->get_phone( $html );
	$fax = $self->get_fax( $html );
	$zip = $self->get_zip( $html );

	push (@{$detail}, $email, $phone, $fax, $zip);
	return $detail;
}

sub get_email
{
    my ($self, $html) = @_;
    return '' unless $html;
    my ($email) = $html =~ m{
			([\w\.\-]+\@[\w\.\-]+\.(com|edu|org|net|gov|mil|info|us|uk|ca|cn|de|tv|jp){1}(\.(\w{2}))?)\b
	}six;
    return $email;
}

sub get_phone {
    my ($self, $html) = @_;
    return '' unless $html;
    # my ($phone) = $html =~ m{phone:\s+([\d\-\(\)\.\ ]{10,})\s}si;
    my ($phone) = $html =~ m{\s([\d\-\(\)\.\ ]{10,})\s}s;
    return '' unless($phone);
    return '' if ($phone=~m/\.{10,}/);  # more..........
    return '' if ($phone=~m/(?:\d\s){3,}/);  # 5 0 0 0 0 0
    $phone =~ s/^\s+// if ($phone=~m/^\s+/); # ' 123'
    $phone =~ s/\s+$// if ($phone=~m/\s+$/); # '123 '
    $phone =~ s/^\.+// if ($phone=~m/^\./);  # '.1(604)'
    $phone =~ s/^-+// if ($phone=~m/^-/);    # '-1(604)'
    $phone = '(' . $phone if ($phone=~m"\)" && $phone!~m"\(");
    $phone =~ s/\s/-/g if ($phone=~m/\s/);      #  '123 456 7890'
    $phone =~ s/-\($// if ($phone=~m/-\($/);  # '6789-('

    return $phone;
}

sub get_fax {
    my ($self, $html) = @_;
    return '' unless $html;

    my ($fax) = $html =~ m{fax:\s+([\d\-\(\)\.]{10,})\s}si;
    return '' unless($fax);
    return '' if ($fax=~m/\.{10,}/);  # more..........
    return '' if ($fax=~m/(?:\d\s){3,}/);  # 5 0 0 0 0 0

    $fax =~ s/^\s+// if ($fax=~m/^\s+/); # ' 123'
    $fax =~ s/\s+$// if ($fax=~m/\s+$/); # '123 '
    $fax =~ s/^\.+// if ($fax=~m/^\./);  # '.1(604)'
    $fax =~ s/^-+// if ($fax=~m/^-/);    # '-1(604)'
    $fax = '(' . $fax if ($fax=~m"\)" && $fax!~m"\(");
    $fax =~ s/\s/-/g if ($fax=~m/\s/);      #  '123 456 7890'
    $fax =~ s/-\($// if ($fax=~m/-\($/);  # '6789-('

    return $fax;
}

sub get_zip {
    my ($self, $html) = @_;
    return '' unless $html;
    my ($zip) = $html =~ m{
		(?:zip|postcal|post\s):\s+([\w\s]{5,7})\s
	}six;
    return $zip;
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


sub get_emails 
{
	my ( $self, $html ) = @_;
	my $email_aref = [];
	while (
		$html =~ m{
			([\w\.\-]+\@[\w\.\-]+\.(com|edu|org|net|gov|mil|info|us|uk|ca|cn|de|tv|jp){1}(\.(\w{2}))?)\b
	}sgix) {
		push( @{$email_aref}, $1 );
	}
	return $email_aref;
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

sub uniq_links {
	my ($self, $arr) = @_;
	undef(@{$self->{uniq_links}});
	@{$arr} = sort(@$arr);
	$self->{uniq_links}->[0] = $arr->[0];

	# Can't use grep coz of special chars.
	for (my $i=0; $i<scalar(@{$arr}); $i++) {
		if ($self->{uniq_links}->[-1] ne $arr->[$i]) {
			push (@{$self->{uniq_links}}, $arr->[$i]);
		}
	}
	return $self->{uniq_links};
}


################################ yahoo parse.  ################################ 
# use for yy.pl. yahoo.com can pagnation, google.com can't.
sub strip_yahoo
{
	my ( $self, $html ) = @_;

	my $striped_html = undef;
	$html =~ m {
			<div\sid="pg">
			(.*?)
			class="bdc"
	}sgix;
	return $1;
}

sub parse_yahoo_page
{
    my ( $self, $html ) = @_;
    return unless $html;
	$html =~ m {
        <strong>
		(\d+)
        </strong>
		\s*
        <a\s
		(?:.*?)
		href="(.*?)"
		(?:.*?)
		>
		(\d+)
        </a>
    }sgix;
	my ($cur_page, $alink, $next_page) = ($1, $2, $3);
	return [ $cur_page, $alink, $next_page ];
}

sub get_last_id {
    my ($self, $email) = @_;
    # $sth = $self->{dbh}->prepare( q{ select last_insert_id(); } );
    $sth = $self->{dbh}->prepare( q{ select id from }. CONTACTS . qq{ where email = '$email' } );
    $sth->execute();
    my @row = $sth->fetchrow_array();
    $sth->finish();
    return $row[0];
}

1;
