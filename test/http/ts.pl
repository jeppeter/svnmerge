#! perl -w
use strict;
use warngings;
use IO::Socket::INET;
use IO::Select;
use POSIX;
use POSIX ":sys_wait_h";
use Getopt::Std;
use vars qw ($opt_h);

getopt("h");
if (defined($opt_h))
{
	
}

