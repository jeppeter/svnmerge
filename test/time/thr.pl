#! perl

use threads;
use threads::shared;
use Time::HiRes qw (usleep);

my (@array,$arrayref);
my (%hashb,$href);
my ($thra,$thrb);

share(@array);
share($arrayref);
share(%hashb);
share($href);

sub AThr(@)
{
	my ($href)=@_;
	my ($aref);
	my ($i);
	$SIG{'KILL'} = sub{print "In Thread exit\n"; threads->exit(3)};

	for ($i=0;1;$i++)
	{
		{
			lock($href);
			$aref = $href->{_array};
			push(@{$aref},$i);
			print "In A($i) push $i\n";
			print "In A($i) array @{$aref}\n";			
		}
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

	for ($i=0;$i < 20;$i++)
	{
		usleep(100000);
		undef($get);
		@barray=();
		if (defined($href->{_array}))
		{
			lock($href);
			$aref = $href->{_array};			
			@barray = @{$aref};
			@{$aref} = ();
		}
		if ($#barray > 0)
		{
			print "In B($i) pop (@barray)$#barray\n";
			$self->{_stored}=[@barray];
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



$arrayref= \@array;
$href = \%hashb;
$href->{_array} = $arrayref;
$href->{_ended} = 0;
$thra = threads->create(\&AThr,$href);
$thrb = threads->create(\&BThr,$href);
share($thra);
share($thrb);
$thrb->join();
$thra->kill('KILL');
$thra->join();
