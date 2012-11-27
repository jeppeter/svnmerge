# this package for the 

package DirTime ;

sub _DebugString
{
    my ($self,$str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub new
{
	my ($class) =@_;
	my ($self) = {};

	bless $self,$class;
	$self->{_cont} = 1;
	return $self;
}

sub SetDir
{
	my ($self,$dir)=@_;

	if ($self->{_dir})
	{
		undef($self->{_dir});
	}
	if ($self->{_curidx})
	{
		# index is 0 for it will make the compare ok
		$self->{_curidx} = 0;
	}
	$self->{_dir} = $dir;
	return $self;
}

sub SetFiles
{
	my ($self,@files)=@_;
	my (@formfiles)=();
	if (defined($self->{_array}))
	{
		undef($self->{_array});
	}

	
	while(@files)
	{
		my ($_cur)=shift @files;
		if (length($_cur))
		{
			push(@formfiles,$_cur);
		}
	}

	$self->{_curidx} = 0;
	$self->{_array} = [@formfiles];
	return $self;
}

sub _GetNextFile
{
	my ($self) = @_;
	if (defined($self->{_array}) && defined($self->{_array}[$self->{_curidx}+1]))
	{
		$self->{_curidx} += 1;
		$self->{_cont}=1;
		return $self->{_array}[$self->{_curidx}];
	}
	
	if (defined($self->{_array}[$self->{_curidx}]))
	{
		$self->{_curidx} += 1;
	}
	return undef;
}


