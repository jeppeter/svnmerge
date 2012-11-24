#! perl -w

sub SigHandler
{
	print "Call SigInt\n";
}

$SIG{'INT'}="SigHandler";

while(1)
{
	print "Running\n";
	sleep(1);
}
