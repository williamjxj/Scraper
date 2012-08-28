package buse;
# Quantifier follows nothing in regex; marked by <-- HERE in m/? <-- HERE o=contact/ at buse.pm line 111.
# Invalid [] range "s-i" in regex; marked by <-- HERE in m/sales@[remove-this-i <-- HERE ncluding-brackets]rand.uk.com/ at ukbusiness.pm line 100.

use lib qw(../lib);
use business_config;
use common;
use Data::Dumper;
@ISA = qw(common);
use strict;
our ( $sth );

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'business';
	$self->{deposits} = [ 'contact', 'about', 'email' ];
	$self->{sql} = [
		q{ select web, id from } . CONTACTS . qq{ where have_email='N' and accessible='Y' order by id limit 0, 200000 }, 
		q{ select web, id from } . CONTACTS . qq{ where have_email='N' and accessible='Y' order by id desc limit 0, 200000 }, 
		q{ select web, id from } . CONTACTS . qq{ where have_email='N' and accessible='N' and reason='frameset' order by id desc limit 0, 100 }, 
	];
	$self->{uniq_links} = [];
	$self->{uniq_emails} = [];

	bless $self, $type;
}

# mailto:sales@rkymtn.com?subject=Sales%20Request
sub get_emails {
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

sub get_frameset {
	my ( $self, $html ) = @_;
	my $email_aref = [];
	my $furl;
	while (
		$html =~ m{
			<frame
			(?:.*?)
			src=.*?
			(\b|"|>)
	}sgix) {
		$furl = $1;
		$furl =~ s/\"//g if ($furl=~/\"/);
		push( @{$email_aref}, $furl );
	}
	return $email_aref;
}

# http://www.calvaryapostolic.com no </a>
# graceful exit when not match.
sub get_hrefs {
	my ( $self, $html ) = @_;
	my $hrefs = [];
	while ($html =~ m{
		<a\s
		(?:.*?)
		href="(.*?)"
		(?:.*?)
		>
		(.*?)
		(</a>|<\/body>|<\/html>)
	}sgix) {
		my ($elinks, $str) = ($1, $2);
		next unless $str;

		$str=~s/\r//g if ($str=~/\r/);
		$str=~s/\n//g if ($str=~/\n/);
		# print "[" . $elinks . "], [" . $str. "]\n" if (defined $self->{web_flag});

		if (grep{ $str =~ m{$_}i } @{$self->{deposits}}) {
			$elinks =~ s/mailto://i if ($elinks =~ m/mailto:/i);
			$elinks = $self->trim($elinks);
			push( @{$hrefs}, $elinks);
		}
		elsif ($str=~m/\<img/i && (($str=~m/Email/i)||($str=~m/contact/i))) {
			push( @{$hrefs}, $elinks);
		}
	}
	# print Dumper($hrefs) if (defined $self->{web_flag});
	return $hrefs;
}

sub select_category {
	my ( $self, $cond ) = @_;
	if (defined $cond) {
		if ($cond eq '1') {
			$sth = $self->{dbh}->prepare( $self->{sql}->[1] );
		}
		elsif ($cond eq '2') {
			$sth = $self->{dbh}->prepare( $self->{sql}->[2] );
		}
		elsif ($cond eq '3') {
			$sth = $self->{dbh}->prepare( $self->{sql}->[3] );
		}
		elsif ($cond eq '4') {
			$sth = $self->{dbh}->prepare( $self->{sql}->[4] );
		}
	}
	else {
		$sth = $self->{dbh}->prepare( $self->{sql}->[0] );
	}
	$sth->execute();
	my $all = $sth->fetchall_arrayref();
	$sth->finish();
	return $all;
}

sub get_id {
	my ( $self, $web ) = @_;
	$web =~ s{^http://}{}  if ($web =~ m/^http:/);
	$web =~ s{/$}{} if ($web =~ m/\/$/);
	$sth = $self->{dbh}->prepare( q{ select id from }. CONTACTS . qq{ where web = '$web' } );
	$sth->execute();
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

# contact link maybe duplicate.
# deprecated, how about 'abc@hotmail.com' includes 'bc#hotmail.com' ??
sub uniq_emails {
    my ($self, $arr) = @_;
	undef(@{$self->{uniq_emails}});
    foreach my $var ( @{$arr} ) {
		if ( ! grep( /$var/, @{$self->{uniq_emails}} ) ){
			push( @{$self->{uniq_emails}}, $var );
		}
	}
	return $self->{uniq_emails};
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

1;
