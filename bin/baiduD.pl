#!/usr/bin/perl -w
=comment
http://stackoverflow.com/questions/766397/how-can-i-run-a-perl-script-as-a-system-daemon-in-linux
1. Fork a child and exits the parent process.
2. Become a session leader (which detaches the program from the controlling terminal).
3. Fork another child process and exit first child. This prevents the potential of acquiring a controlling terminal.
4. Change the current working directory to "/".
5. Clear the file creation mask.
6. Close all open file descriptors.
=cut

use strict;
use warnings;
use Proc::Daemon;

Proc::Daemon::Init;

my $continue = 1;
$SIG{TERM} = sub { $continue = 0 };

while ($continue) {
     #do stuff
}