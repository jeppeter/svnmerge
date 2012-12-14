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

sub _GetCurFile
{
	my ($self) = @_;
	if (defined($self->{_array}) && defined($self->{_array}[$self->{_curidx}]))
	{
		return $self->{_array}[$self->{_curidx}];
	}
	return undef;
}

sub _GetTime
{
    my ($self,$file)=@_;
    my ($filename);
    my ($mtime,@attr);

	# if not set ,we use 0 for default
    $mtime = "0";

    $filename = "$self->{_dir}"."/$file";
    if( -f $filename )
    {
    	@attr = stat($filename);
    	if (@attr > 0)
    	{
    		$mtime = $attr[9];
    	}
    }    
    return $mtime;
}


sub GetCmpString
{
	my ($self) = shift @_;
	my ($file) = shift @_;
	my ($omtime) = shift @_;
	my ($str,$curmtime,$curfile,$cont);

	if (!defined($self->{_dir}) || !defined($self->{_array}))
	{
		my ($p,$f,$l,$F) = caller(0);
		die "[$p][$f][$F]$l: Not Init the dir or array\n";
	}

	undef($str);
	$cont=0;
	if (defined($file) && defined($omtime))
	{
		# it is the file
		# test if we have a file to do
		$curfile = $self->_GetCurFile();
		if (defined($curfile))
		{
			# 
			if ( "$curfile" lt "$file" )
			{
				$str = "+ $curfile\n";
				# get next file
				$curfile=$self->_GetNextFile();
				if (defined($curfile))
				{
					$cont = 1;
				}
				else
				{
					# this will not set this again ,so 
					# we should set here
					$str .= "- $file\n";
				}
			}
			elsif ( "$curfile" gt "$file" )
			{
				$str = "- $file\n";
			}
			else
			{
				# get next one
				$curmtime = $self->_GetTime($curfile);
				if ( $curmtime < $omtime )
				{
					# it means current file is old so do not use any one
				}
				else if ( $curmtime > $omtime )
				{
					# it means current file is young
					$str = "Y $curfile\n";
				}
				# get next one
				$self->_GetNextFile();
			}
		}
		else
		{
			# no file ,so we should
			$str = "- $file\n";
		}
		
	}
	elsif (defined($file))
	{
		# it is the directory
		
		$curfile = $self->_GetCurFile();
		#$self->_DebugString("Diff $file <=> ".(defined($curfile) ? "$curfile" : "Not curfile")."\n");
		if (defined($curfile))
		{
			if ( "$curfile" lt "$file" )
			{
				$str = "+ $curfile\n";
				# get next file
				$curfile = $self->_GetNextFile();
				#$self->_DebugString("Diff $file <=> ".(defined($curfile) ? "$curfile" : "Not curfile")."\n");
				if (defined($curfile))
				{
					$cont = 1;
				}
				else
				{
					# this is ok because we can not continue to compare the 
					# file ,so it is to make it delete
					$str .= "- $file\n";
				}
			}
			elsif ( "$curfile" gt "$file" )
			{
				#$self->_DebugString("Diff $file <=> ".(defined($curfile) ? "$curfile" : "Not curfile")."\n");
				$str = "- $file\n";
			}
			else
			{
				# get next one
				#$self->_DebugString("Diff $file <=> ".(defined($curfile) ? "$curfile" : "Not curfile")."\n");
				$self->_GetNextFile();
				undef($str);
			}
		}
		else
		{
			#$self->_DebugString("Diff $file <=> ".(defined($curfile) ? "$curfile" : "Not curfile")."\n");
			$str = "- $file\n";
		}
	}
	else
	{
		# it is nothing to do ,so we should get it
		# it is in the last
		$curfile = $self->_GetCurFile();
		if (defined($curfile))
		{
			$str = "+ $curfile\n";
			$curfile = $self->_GetNextFile();			
			if (defined($curfile))
			{
				$cont = 1;
			}
			else
			{
				# now the $file is null so we do not add the 
				# new - $file.
			}
		}
	}
	return ($str,$cont);
}

sub FormTime
{
	my ($self) =@_;
	my ($file,$mtime);
	my ($str,$cont,$fname);

	if (!defined($self->{_dir}) || !defined($self->{_array}))
	{
		my ($p,$f,$l,$F) = caller(0);
		die "[$p][$f][$F]$l: Not Init the dir or array\n";
	}

	$file = $self->_GetCurFile();
	$cont = 0;
	if (defined($file))
	{
		$fname = "$self->{_dir}"."/$file";
		if ( -f $fname )
		{
			$mtime = $self->_GetTime($file);
			$str = "F $file\n";
			$str .= "T $mtime\n";
		}
		elsif ( -d $fname )
		{
			if (length($file))
			{
				$str = "F $file\n";
			}
		}
		$file = $self->_GetNextFile();
		if (defined($file))
		{
			$cont = 1;
		}
	}
	return ($str,$cont);
}


sub PrepareInit
{
	my ($self) = @_;

	if (!defined($self->{_dir}) || !defined($self->{_array}))
	{
		my ($p,$f,$l,$F) = caller(0);
		die "[$p][$f][$F]$l: Not Init the dir or array\n";
	}
	
	$self->{_curidx} = 0;
	# to pretend this is for the continue
	$self->{_cont} = 1;
	return $self;
}

sub DESTROY
{
	if(defined($self->{_array}))
	{
		undef($self->{_array});
	}
}

1;


