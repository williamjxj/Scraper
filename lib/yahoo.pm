package yahoo;

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

1;