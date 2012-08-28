package business;

use lib qw(../lib);
use business_config;
use common;
use Data::Dumper;
@ISA = qw(common);
use strict;
our ( $dbh, $sth );

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'business';
	$self->{deposits} = [ 'contact us', 'contact', 'email' ];
	bless $self, $type;
}

sub get_emails {
	my ( $self, $html ) = @_;
	my $email_aref = [];

	while (
		$html =~ m{
			\b([\w\.\-]+@[\w\.\-]+)\b
	}sgix) {
		push( @{$email_aref}, $1 );
	}
	return $email_aref;
}

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
		</a>
	}sgix) {
		my ($elinks, $str) = ($1, $2);
		next unless $str;
		next if ($str =~ m/\{/);
		next if ($str =~ m/\<area shape/);
		next if ( ($str=~m/\</) or ($str=~m/\/\>/) );
		next if ( ($str=~m/\[/) or ($str=~m/\]/) );
		next if ($str=~m/\*/);
		next if ($str=~m/\(/ or ($str=~m/\)/) );
		next if ($str eq '?');

		$str =~ s/\+//g if ($str=~m/\+/);
		# $str =~ s/\?/\\?/g if ($str=~m/\?/);
		# print "[" . $elinks . "], [" . $str. "]\n";

		# if (grep{ $_ =~ m{$str}i } @{$self->{deposits}}) 
		if (grep{ $str =~ m{$_}i } @{$self->{deposits}}) {
			$elinks =~ s/mailto://i if ($elinks =~ m/mailto:/i);
			$elinks = $self->trim($elinks);
			push( @{$hrefs}, $elinks);
		}
		elsif ($str=~m/\<img/i && (($str=~m/Email/i)||($str=~m/contact/i))) {
			push( @{$hrefs}, $elinks);
		}
		elsif ($str=~m/skip/i) {
			#push( @{$hrefs}, $elinks);
		}
	}
	# print Dumper($hrefs);
	return $hrefs;
}

# $sth = $self->{dbh}->prepare( q{ select web, id, category, name, address, county, city, state from } . CONTACT . qq{ where name like 'martial art%' });
# email  defaults: NULL
sub select_category {
	my ( $self, $cond ) = @_;
	my @row = ();
	if (defined $cond) {
		$sth = $self->{dbh}->prepare( q{ select web, id from } . CONTACT . qq{ where email is null and accessible = 'Y' order by id desc limit 0,1000});
	}
	else {
		$sth = $self->{dbh}->prepare( q{ select web, id from } . CONTACT . qq{ where email is null and accessible = 'Y'  limit 0,1000 });
	}
	$sth->execute();
	my $all = $sth->fetchall_arrayref();
	$sth->finish();
	return $all;
}

sub get_id {
	my ( $self, $web ) = @_;
	$web =~ s{^http://}{} if ($web =~ m/^http:/);
	$web =~ s{/$}{} if ($web =~ m/\/$/);
	my $sth =
	  $self->{dbh}->prepare( qq{ select id from biz_us_contact where web like '%$web%' } );
	$sth->execute();
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

sub get_us_end_date {
	my ( $self, $todate ) = @_;
	my $sth =
	  $self->{dbh}->prepare( qq{ select date_format(date_sub(now(), interval } 
		  . $todate
		  . qq{ day), '%a %b %d' ) } );
	$sth->execute();
	my @row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}

# contact link maybe duplicate.
sub uniq {
    my ($self, $arr) = @_;
    my @uniqarr;

    foreach my $var ( @{$arr} ){
		return $arr if ($var=~m/\?/);
       if ( ! grep( /$var/, @uniqarr ) ){
          push( @uniqarr, $var );
          }
    }
    return \@uniqarr;
}


1;
