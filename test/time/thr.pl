#! perl

use threads;
use threads::shared;
use Time::HiRes qw (usleep);

my (@array,$arrayref);


share(@array);
share($arrayref);

sub AThr(@)
{
	my ($aref)=@_;
	my ($i);

	for ($i=0;$i< 20;$i++)
	{
		{
			lock($aref);
			push(@{$aref},$i);
			print "In A array @{$aref}\n";			
		}
		print "In A push $i\n";
		usleep(1000);
	}
}

sub BThr(@)
{
	my ($aref)=@_;
	my ($i,$get);
	my (@barray);

	for ($i=0;$i< 20;$i++)
	{
		usleep(1000);
		undef($get);
		@barray=();
		{
			lock($aref);
			while(defined($get = shift(@{$aref})))
			{
				push(@barray,$get);
			}
			print "In B array @{$aref}\n";
		}
		if (length(@barray) > 0)
		{
			print "In B($i) pop @barray\n";
		}
		else
		{
			print "In B($i) pop nothing\n";
		}
	}
}


my ($thra,$thrb);

$arrayref= \@array;
$thra = threads->create(\&AThr,$arrayref);
$thrb = threads->create(\&BThr,$arrayref);

$thra->join();
$thrb->join();
