#! perl

use threads;
use threads::shared;
use Time::HiRes qw (usleep);

my (@array,$arrayref);
my (%hashb,$href);


share(@array);
share($arrayref);
share(%hashb);
share($href);

sub AThr(@)
{
	my ($href)=@_;
	my ($aref);
	my ($i);

	for ($i=0;$i< 20;$i++)
	{
		{
			lock($href);
			$aref = $href->{_array};
			push(@{$aref},$i);
			print "In A array @{$aref}\n";			
		}
		print "In A push $i\n";
		usleep(1000);
	}
	{
		lock($href);
		$href->{_ended} = 1;		
	}
	return 0;
}

sub BThr(@)
{
	my ($href)=@_;
	my ($i,$get);
	my (@barray,$isended);
	my ($aref);

	for ($i=0;$i< 20;$i++)
	{
		usleep(1000);
		undef($get);
		@barray=();
		{
			lock($href);
			$aref = $href->{_array};
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

	{
		lock($href);
		$get = $href->{_ended};		
	}

	print "In B ended $get\n";
	return 0;
}


my ($thra,$thrb);

$arrayref= \@array;
$href = \%hashb;
$href->{_array} = $arrayref;
$href->{_ended} = 0;
$thra = threads->create(\&AThr,$href);
$thrb = threads->create(\&BThr,$href);

$thra->join();
$thrb->join();
