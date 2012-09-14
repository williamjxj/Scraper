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

	my $nowtime = sprintf ("%02d%02d%02d", $time->[2], $time->[1], $time->[0]);
	my $nowdate = sprintf ("%02d%02d%02d", ($time->[5]+1900)%100, $time->[4]+1, $time->[3]);

	return $nowdate if ($choice eq '1');
	return $nowtime if ($choice eq '2');
	# return "$nowdate|$nowtime|";
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
	return;
    $self->{log}->close();
}

#-------------------------------
# Parsing
#-------------------------------
sub get_email
{
    my ($self, $html) = @_;
	return '' unless $html;
	my ($email) = $html =~ m{\b([\w\.\-]+@[\w\.\-]+)\b}s;
	return $email;
}

# phone: New $15,000.00  web: Asking $10,900.00. 
# http://www.jt-hotshotting.com
# ($web)=$html=~m{[^@](?:\b)((?:[\w\-]+$pattern)(\s|<)}si;
sub get_web
{
	my ($self, $html) = @_;
	return '' unless $html;
	# ($web) = $html =~ m{((http://|www\.)?(?:[\w\-]+\.){1,5}\w+(/\S*)?)}is;
    my ($web) = $html =~ m{((http://|www\.)(?:[\w\-]+\.){1,5}\w+(/\S*)?)}sig;

	# '<b><font size="5">TheEssayCoach.com</font> offers',
	#  Email mailto:ethnojammusic@yahoo.ca
	unless ($web) {
		my $pattern = "(\.com|\.ca|\.info|\.us|\.tv|.gov)";
		if ($html=~m/$pattern/i) {		
			($web) = $html =~ m{[^@](?:\b)((?:[\w\-]+\.){1,5}(com|us|info|ca|jpg|png|jpeg|gif)(/\S*)?)}sig;
		}
	}
	$web =~ s/<.*$// if ($web && $web=~m/<.*$/);
	$web =~ s/">.*$// if ($web && $web=~m/">/);
	$web =~ s/&amp;/&/g if ($web && $web=~m/&amp;/);
	$web =~ s/\S$// if ($web && $web=~m/["';,?]$/);
	return $web;
}

sub get_phone
{
	my ($self, $html) = @_;
	return '' unless $html;
	$html =~ s/<img.*?>//g;
	my ($phone) = $html =~ m{(?:\b|<b>)?([\d\-\(\)\.]{10,})(?:\b|</b>|\s)}s;
	return '' unless($phone);
	return '' if ($phone=~m/\.{10,}/); 	# more..........
	return '' if ($phone=~m/(?:\d\s){3,}/);  # 5 0 0 0 0 0
	$phone =~ s/^\s+// if ($phone=~m/^\s+/); # ' 123'
	$phone =~ s/\s+$// if ($phone=~m/\s+$/); # '123 '
	$phone =~ s/^\.+// if ($phone=~m/^\./);	 # '.1(604)'
	$phone =~ s/^-+// if ($phone=~m/^-/);	 # '-1(604)'
	$phone = '(' . $phone if ($phone=~m"\)" && $phone!~m"\(");
	$phone =~ s/\s/-/g if ($phone=~m/\s/);		#  '123 456 7890'
	$phone =~ s/-\($// if ($phone=~m/-\($/);  # '6789-('
	return $phone;
}


# $str =~ s/'/\'/g if ($str =~ m/'/);
sub trim
{
	my ($self, $str) = @_;
	return '' unless $str;

	$str =~ s/&nbsp;/ /g if ($str =~ m/&nbsp;/);
	$str =~ s/&amp;/&/g if ($str =~ m/&amp;/);
	$str =~ s/^\s+// if ($str =~ m/^\s/);
	$str =~ s/\s+$// if ($str =~ m/\s$/);
	return $str;
}


1;
