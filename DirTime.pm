# this package for the 

package DirTime ;

use threads;
use threads::shared;
use Time::HiRes qw(usleep);
use FindSort;

sub _DebugString
{
    my ($self,$str)=@_;
    my ($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}

sub __SetError
{
	my ($self,$exitcode,$msg)=@_;
	$self->{_exitcode} = $exitcode;
	$self->{_msg}=$msg;
	return $exitcode;
}

sub GetError
{
	my ($self)=@_;
	return defined($self->{_msg}) ? $self->{_msg} : "";
}


sub new
{
	my ($class) =@_;
	my ($self) = shared_clone({});
	my ($href);

	bless $self,$class;
	share($self->{_hash});
	$self->{_hash} = shared_clone({});
	$href = $self->{_hash};
	$href->{_array} = shared_clone([]);
	$href->{_filters} = shared_clone([]);
	$href->{_ended} = 0;
	$href->{_thrid} = 0;
	$href->{_dir} = "";
	share($href->{_array});
	share($href->{_filters});
	share($href->{_ended});
	share($href->{_thrid});
	share($href->{_dir});
	$self->{_stored} = shared_clone([]);
	return $self;
}

sub SetDir
{
	my ($self,$dir)=@_;
	my ($href);

	$href = $self->{_hash};
	#$self->_DebugString("Set Dir $dir\n");
	if (defined($href->{_dir}))
	{
		undef($href->{_dir});
	}
	$href->{_dir} = shared_clone($dir);
	#$self->_DebugString("Set Dir ".$self->{_dir}."\n");
	return $self;
}

sub SetFilters
{
	my ($self,@filters)=@_;
	my ($href);

	#undef($self->{_filters});
	$href = $self->{_hash};
	$href->{_filters} = shared_clone([@filters]);
	return $self;
}

sub __ScanDirCallBack($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	my ($self)=@args;
	my ($href);
	my ($aref);
	my ($relativefname,$tfname);
	my (@sts,$mtime);

	$href = $self->{_hash};
	$tfname = $fname;
	$fname =~ s/^\Q$dir\E[\/\\]+//;
	$relativefname = $fname;
	{
		# now to push the file
		lock($href);
		$aref = $href->{_array};
		push(@{$aref},$relativefname);
		#$self->_DebugString("push $relativefname to $aref ".scalar(@{$aref})." reftype ".ref($aref)." #@{$aref}#\n");
	}
	
	return 0;
}

sub __ExitThread
{
	threads->exit(3);
}

sub __ScanDir($$@)
{
	my ($self,$dir,@filters)=@_;
	my ($fs,$ret,$aref,$href);

	$SIG{'KILL'} = \&__ExitThread;
	$href = $self->{_hash};

	{
		lock($href);
		$href->{_ended} = 0;
	}
	$fs = FindSort->new();
	$fs->SetCallBack(\&__ScanDirCallBack,$self);
	if (defined($href->{_filters}))
	{
		lock($href);
		$aref = $href->{_filters};
		@filters = @{$aref};
		$fs->SetFilters(@filters);
	}
	$ret = $fs->ScanDirs($dir);

	{
		lock($href);
		$href->{_ended} = 1;
	}

	threads->exit($ret);
}

sub StartScanDir
{
	my ($self,$dir)=@_;
	my ($thrid);
	my (@filters,$aref);
	my ($href);

	$href = $self->{_hash};
	if (defined($href->{_thrid}) && $href->{_thrid} )
	{
		$thrid = $href->{_thrid};
		# now to wait for thread exit
		$thrid->{'KILL'};
		$thrid->join();
	}
	undef($href->{_thrid});


	@fitlers=();
	$aref= $href->{_filters};
	if (defined($aref) && scalar(@{$aref}) > 0)
	{
		@filters = @{$aref};
	}
	$href->{_array}=shared_clone([]);
	$href->{_ended} = 0;
	# now to start 
	$thrid = threads->create(\&__ScanDir,$self,$dir,@filters);
	if (!defined($thrid))
	{
		return -3;
	}
	$href->{_thrid} = shared_clone($thrid);

	# now to return ok
	return 0;	
}

sub _GetNextFile($)
{
	my ($self)=@_;
	my (@retarr,$retfile);
	my ($isended,$aref);
	my ($href);

	$href = $self->{_hash};
try_again:
	undef($retfile);
	undef($self->{_curfile});
	if (defined({$self->{_stored}}))
	{
		$aref = $self->{_stored} ;
		#$self->_DebugString("pop array @{$aref}#$aref#(".scalar(@{$aref}).")\n");
		$retfile = shift(@{$aref});
	}
	if (defined($retfile))
	{
		#$self->_DebugString("shift ($retfile)\n");
		$self->{_curfile} = $retfile;
		return $retfile;
	}

	
	@retarr = ();
	$isended = 0;
	do	
	{
		{
			lock($href);
			if (defined($href->{_array}))
			{
				$aref = $href->{_array};
				@retarr = @{$aref};
				$href->{_array}=shared_clone([]);
			}
			$isended = $href->{_ended};
		}

		if (scalar(@retarr) > 0)
		{
			#$self->_DebugString("retarr @retarr\n");
		}
		if ($isended == 0 && scalar(@retarr) == 0)
		{
			usleep(1000);
		}		
	}while($isended == 0 && scalar(@retarr) == 0);

	
	$self->{_stored} = shared_clone([@retarr]);
	$aref = $self->{_stored};
	#$self->_DebugString("stored (@{$aref})".scalar(@{$aref})."\n");
	if (scalar(@retarr) > 0)
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
	return defined($self->{_curfile}) ? $self->{_curfile} : $self->_GetNextFile();
}

sub _GetTime
{
    my ($self,$file)=@_;
    my ($filename);
    my ($mtime,@attr);
    my ($href);

	# if not set ,we use 0 for default
    $mtime = "0";

	$href = $self->{_hash};
    $filename = "$href->{_dir}"."/$file";
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
	my ($href);

	$href = $self->{_hash};
	if (!defined($href->{_dir}) )
	{
		my ($p,$f,$l,$F) = caller(0);
		$self->_DebugString("dir ".(defined($href->{_dir}) ? $href->{_dir} : "null")." \n");
		die "[$p][$f][$F]$l: Not Init the dir or array\n";
	}
	#$self->_DebugString(" CmpString file ".(defined($file) ? $file: "null")." omtime ".(defined($omtime) ? $omtime : "null")."\n");

	undef($str);
	$cont=0;
	if (defined($file) && defined($omtime))
	{
		# it is the file
		# test if we have a file to do
		$curfile = $self->_GetCurFile();
		if (defined($curfile))
		{
			#$self->_DebugString("curfile $curfile\n");
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
				#$self->_DebugString("$curfile $omtime <=> $curmtime\n");
				if ( $curmtime < $omtime )
				{
					# it means current file is old so do not use any one
				}
				elsif ( $curmtime > $omtime )
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



sub DESTROY
{
	my ($self)=@_;
	my ($href,$ret);
	if (defined($self->{_hash}))
	{
		$href = $self->{_hash};
	}
	if (defined($href->{_thrid}))
	{
		my ($thrid) = $href->{_thrid};
		#$thrid->kill('KILL');
		$ret =$thrid->join();
		undef($href->{_thrid});
		undef($thrid);
	}
	if (defined($self->{_stored}))
	{
		undef($self->{_stored});
	}
	if(defined($href->{_array}))
	{
		undef($href->{_array});
	}
}



1;


