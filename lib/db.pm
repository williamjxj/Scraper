package db;

use Data::Dumper;
use strict;
use utf8;

# 这里,没有返回类目标, 而是返回它的一个属性句柄, 所以没有办法继承.
sub new
{
    my ($type, $user, $pass, $dsn) = @_;
    my $self = {};
	$self->{dbh} = DBI->connect($dsn, $user, $pass, { RaiseError=>1 });
	$self->{dbh}->do('SET NAMES "utf8"');
	# mysql_query("SET NAMES 'UTF8'");
	# mysql_query("SET CHARACTER SET UTF8");
	# mysql_query("SET CHARACTER_SET_RESULTS='UTF8'");
	bless $self, $type;
	return $self->{dbh};
}

1;
