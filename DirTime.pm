# this package for the 

package DirTime ;

use threads;
use threads::shared;
use Time::HiRes qw(usleep);


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

sub SetFilters
{
	my ($self,@filters)=@_;


	undef($self->{_filters});
	$self->{_filters} = [@filters];
	share($self->{_filters});
	return $self;
}

sub __ScanDirCallBack($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	my ($self)=@args;
	my ($aref);
	my ($relativefname,$tfname);
	my (@sts,$mtime);

	$tfname = $fname;
	$fname =~ s/^\Q$dir\E[\/\\]+//;
	$relativefname = $fname;

	{
		# now to push the file
		lock($self);
		$aref = $self->{_array};
		push(@{$aref},$relatetivefname);
	}
	return 0;
}

sub __ScanDir($$)
{
	my ($self,$dir)=@_;
	my ($fs,$ret);


	{
		lock($self);
		$self->{_ended} = 0;
	}
	$fs = FindSort->new();
	$fs->SetCallBack(\&__ScanDirCallBack,$self);
	$fs->SetFilters(@filters);
	$ret = $fs->ScanDirs($dir);

	{
		lock($self);
		$self->{_ended} = 1;
	}

	return $ret;
}

sub __StartScanDir
{
	my ($self,$dir)=@_;

	
}

sub __GetNextFile($)
{
	my ($self)=@_;
	my (@retarr,$retfile);
	my ($isended,$aref);

try_again:
	undef($retfile);
	undef($self->{_curfile});
	if (defined({$self->{_stored}}))
	{
		$aref = $self->{_stored} ;
		$retfile = shift(@{$aref});
	}
	if (defined($retfile))
	{
		$self->{_curfile} = $retfile;
		return $retfile;
	}

	
	@retarr = ();
	$isended = 0;
	do	
	{
		{
			lock($self);
			if (defined($self->{_array}))
			{
				$aref = $self->{_array};
				@retarr = @{$aref};
			}
			$isended = $self-{_ended};
		}

		if ($isended == 0 && @retarr == 0)
		{
			usleep(1000);
		}		
	}while($isended == 0 && @retarr == 0);

	
	$self->{_stored} = [@retarr];
	if (@retarr > 0)
	{
		goto try_again;
	}
	# nothing to do ,so return null
	return undef;
}


sub _GetCurFile
{
	my ($self) = @_;
	# we call get the next file ,because in the first ,we not defined the $self->{_curfile}
	return defined($self->{_curfile}) ? $self->{_curfile} : $self->__GetNextFile();
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


