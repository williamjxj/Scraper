#!/usr/bin/perl -w
# Generally anonymous pipes are used for communication between related processes (parent-child, for example),
# and named pipes (on UNIX, also called FIFO's) for communication between unrelated processes.
use strict;
use warnings;
use Data::Dumper;

my $result;
my $named_pipe_name = '/home/williamjxj/pipes/baidu';
my $timeout         = 5;
my $errormsg;

if ( -p $named_pipe_name ) {

	eval {
		local $SIG{ALRM} = sub { die "alarm\n" };    # NB: \n required
		alarm $timeout;
		if ( sysopen( FIFO, $named_pipe_name, O_RDONLY ) ) {
			while ( my $this_line = <FIFO> ) {
				chomp($this_line);
				$result .= $this_line;
			}
			close(FIFO);
		}
		else {
			$errormsg =
"ERROR: Failed to open named pipe $named_pipe_name for reading: $!";
		}
		alarm 0;
	};
	if ($@) {
		if ( $@ eq "alarm\n" ) {

			# timed out
			$errormsg = "Timed out reading from named pipe $named_pipe_name";
		}
		else {
			$errormsg = "Error reading from named pipe: $!";
		}
	}
	else {

		# didn't time out
		print STDOUT "$result\n";
	}

}
