#! perl

package TestShared;
use threads;
use threads::shared;
use Time::HiRes qw (usleep);

sub _DebugString
{
    my ($self,$str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub __ExitThread
{
	threads->exit(3);
}

sub new
{
	my ($class) =@_;
	my ($self) = {};

	bless $self,$class;
	$self->{_array} = [];
	$self->{_ended} = 0;
	$self->{_thrid} = 0;
	share($self);
	share($self->{_ended});
	share($self->{_array});
	share($self->{_thrid});
	share($self->{_stored});
	return $self;	
}
sub ThrA
{
	my ($self)=@_;
	my ($i,$aref);

	$SIG{'KILL'} = \&__ExitThread;
	for ($i=0;1;$i++)
	{
		{
			lock($self);
			$aref = $self->{_array};
			push(@{$aref},$i);
			$self->_DebugString("A push($i) $i $aref @{$aref}\n");
		}

		usleep(1000);
	}

	threads->exit(0);
}

sub ThrB
{
	my ($self)=@_;
	my ($i,$aref,@retarr);
	my ($thrid);

	$self->{_stored} = shared_clone([]);
	$thrid = threads->create(\&ThrA,$self);
	if (!defined($thrid))
	{
		$self->_DebugString("can not create threads\n");
		return -3;
	}
	$self->{_thrid} = shared_clone($thrid);
	for ($i=0;$i<20;$i++)
	{
		usleep(100000);
		@retarr = ();
		{
			lock($self);
			$aref = $self->{_array};
			@retarr = @{$aref};
			$self->{_array} = shared_clone([]);
		}

		if ($#retarr > 0)
		{
			$aref = $self->{_stored};
			$self->_DebugString("array size $#retarr @retarr stored @{$aref}\n");
		}

		$self->{_stored} = shared_clone([@retarr]);
	}

	$self->{_thrid}->kill('KILL');
	$self->{_thrid}->join();
	undef($self->{_thrid});
	return 0;	
}

1;

