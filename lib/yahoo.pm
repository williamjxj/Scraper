package yahoo;

use common;
@ISA = qw(common);
use strict;
our ( $sth );

sub new
{
	my ( $class, @args ) = @_;
	my $self = $class->SUPER::new(@args);

	#no need to rebless $self, if parent already blessed: bless $self, $type;
	return $self;
}

# use for yy.pl. yahoo.com can pagnation, google.com can't.
sub strip_result
{
	my ( $self, $html ) = @_;

	my $striped_html = undef;
	$html =~ m {
			<div\sid="main">
			(.*?)
			<div\sid="right">
	}sgix;
	return $1;
}

sub parse_result
{
    my ( $self, $html ) = @_;
    return unless $html;
    my $aoh = [];    
	while ($html =~ m {
		<div\sclass=(?:"res"|res)
		(?:.*?)
		<h3>
		(?:.*?)
		href="
		(.*?)	#1.链接地址
		"
		(?:.*?)
		>
		(.*?)	#2.标题
        </a>
        (?:.*?)
        <div\sclass="abstr"
        (?:.*?)
        >
        (.*?)	#3.正文
        </div>
    }sgix) {
        my ($t1,$t2,$t3) = ($1,$2,$3);
		$t1 =~ s/^\/url\?q=//  if($t1 =~ m/^\/url/);
		$t1 =~ s/\&sa=.*$//  if($t1 =~ m/\&sa=/);
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


# 相关搜索。
sub strip_related_keywords
{
	my ( $self, $html ) = @_;
	return '';
}
sub get_related_keywords
{
	my ( $self, $html ) = @_;
	return [];
}

1;
