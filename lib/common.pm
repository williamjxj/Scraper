package common;

use strict;
use FileHandle;
use Data::Dumper;

#use constant LOGDIR => qq{$ENV{HOME}/scraper/logs/};
use constant LOGDIR => qq{/home/williamjxj/scraper/logs/};
use constant RW_MODE => "a";

sub new
{
    my ($type) = @_;
    my $self = {};
	bless $self, $type;
}

# Use of uninitialized value in pattern match (m//) at lib//common.pm line 20.
# $^O; #MSWin32,Linux
sub get_os_stripname {
	my ($self, $filename) = @_;
	my $stripname; #回车换行.
	if ($^O eq 'MSWin32') {
		$stripname = (defined $filename)?$filename:$self->{osname};		
	}
	else {
		($stripname) = (qx(basename $filename .pl) =~ m"(\w+)");		
	}
	return $stripname;	
}

sub get_filename {
	my ($self, $filename) = @_;
	my ($time, $date);
	@$time = localtime(time);
	my $sn = $self->get_os_stripname($filename);	
	$date = sprintf ("%02d%02d%02d", ($time->[5]+1900)%100, $time->[4]+1, $time->[3]);

	return LOGDIR.$sn.'_'.$date.'.log';
}

sub set_log
{
	my ($self, $logname) = @_;
	my $log = $logname || LOGDIR.__FILE__.".log";
	my $fh = FileHandle->new($log, RW_MODE);
	if (defined $fh) {
		$self->{log} = $fh;
		$self->{log}->autoflush( 1 );
	}
	else {
		die "Error to create log file.";
	}
}

sub get_time
{
	my ($self, $choice) = @_;
	my $time;
	@$time = localtime(time);

	my $nowtime = sprintf (" %02d:%02d:%02d", $time->[2], $time->[1], $time->[0]);
	my $nowdate = sprintf ("%4d-%02d-%02d", $time->[5]+1900, $time->[4]+1, $time->[3]);

	return $nowdate if ($choice eq '1');
	return $nowdate . $nowtime if ($choice eq '2');
}

sub write_log
{
    my ($self, $msg, $varname) = @_;
    return unless $msg;

	if (ref $msg) {
		$Data::Dumper::Varname = $varname || __PACKAGE__;
		print {$self->{log}} Dumper($msg);
	}
	else {
		$msg =~ s"\s+" "g;
		print {$self->{log}} $msg . "\n";		# print $msg . "\n";
	}
}

# last step: graceful exit.
sub close_log {
    my $self = shift;
    $self->{log}->close();
	return;
}

# 将网页抓取的中间结果html文件保存下来,用于debug. 在help/目录下创建link来查看.
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


# 生成随机的数字,用于填充contents表的几列: clicks, likes, guanzhu. 缺省: 0-1000
sub generate_random
{
	my ($self, $range, $min) = @_;
	$range = 1000 unless $range;
	$min = 0 unless $min;
	return int(rand($range)) + $min;
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

sub strip_html
{
	my ($self, $html) = @_;
	$html =~ s/<[^>]+>//g;   # Strip HTML tags
	$html =~ s/\s+/ /g;          # Squash whitespace
    $html =~ s/^ //;     # Strip leading space
    $html =~ s/ $//;     # Strip trailing space
    return $html;
}

1;
