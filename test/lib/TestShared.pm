#! perl

package TestShared;
use threads;
use threads::shared;
use Time::HiRes qw (usleep);
use Random;

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
	$self->_DebugString("self $self\n");
	return $self;	
}
sub ThrA
{
	my ($self)=@_;
	my ($i,$aref);
	my ($ra);

	$SIG{'KILL'} = \&__ExitThread;

	$ra = Random->new();
	
	for ($i=0;1;$i++)
	{
		my ($name);
		$self->_DebugString("self $self\n");
		$name = $ra->GetRandomFileName(20);
		{
			lock($self);
			$aref = $self->{_array};
			push(@{$aref},$name);
			#$self->_DebugString("push($i) $name $aref ".scalar(@{$aref})." (@{$aref})\n");
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
	$self->{_array} = shared_clone([]);
	$thrid = threads->create(\&ThrA,$self);
	if (!defined($thrid))
	{
		$self->_DebugString("can not create threads\n");
		return -3;
	}
	$self->{_thrid} = shared_clone($thrid);
	$self->_DebugString("thrid ".$self->{_thrid}."\n");
	for ($i=0;$i<20;$i++)
	{
		usleep(5000);
		@retarr = ();
		$self->_DebugString("self $self\n");
		{
			lock($self);
			$aref = $self->{_array};
			@retarr = @{$aref};
			$self->{_array} = shared_clone([]);
		}

		if (scalar(@retarr) > 0)
		{
			$aref = $self->{_stored};
			#$self->_DebugString("pop($i) ".scalar(@retarr)." (@retarr) stored (@{$aref})\n");
		}
		else
		{
			#$self->_DebugString("pop($i) null\n");
		}

		$self->{_stored} = shared_clone([@retarr]);
	}

	$self->_DebugString("thrid ".$self->{_thrid}."\n");
	$thrid = $self->{_thrid};
	$thrid->kill('KILL');
	$thrid->join();
	undef($thrid);
	undef($self->{_thrid});
	$self->_DebugString("\n");
	return 0;	
}

1;

