package ukbusiness;

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
	$self->{app} = 'ukbusiness';
	$self->{deposits} = [ 'contact', 'about', 'email' ];
	$self->{sql} = [
		q{ select web, id from } . UKCONTACTS . qq{ where have_email='N' and accessible='Y' order by id limit 0, 100000 }, 
		q{ select web, id from } . UKCONTACTS . qq{ where have_email='N' and accessible='Y' order by id desc limit 0, 100000 }, 
        q{ select web, id from } . UKCONTACTS . qq{ where have_email='N' and accessible='N' and reason='frameset' order by id desc limit 0, 100 },
	];
	bless $self, $type;
}

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
		$sth = $self->{dbh}->prepare( $self->{sql}->[0] );
	}
	else {
		$sth = $self->{dbh}->prepare( $self->{sql}->[1] );
	}
	$sth->execute();
	my $all = $sth->fetchall_arrayref();
	$sth->finish();
	return $all;
}

sub get_id {
	my ( $self, $web ) = @_;
	$web = 'http://' . $web  if ($web !~ m/^http:/);
	$web =~ s{/$}{} if ($web =~ m/\/$/);
	my $sth = $self->{dbh}->prepare( q{ select id from }. UKCONTACTS . qq{ where web = '$web' } );
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
        if ($var !~ m/\@/) {
            if ($var=~m/\+/) {
                $var =~ s/\?/\\\+/g;
            }
            if ($var=~m/\?/) {
                $var =~ s/\?/\\\?/g;
            }
            elsif ($var=~m/\W/) {
                return $arr;
            }
        }

		# return $arr if ($var=~m/\+/);
		# return $arr if ($var=~m/\?/);
		if ( ! grep( /$var/, @uniqarr ) ){
			push( @uniqarr, $var );
		}
	}
	return \@uniqarr;
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
