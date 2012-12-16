#! perl

package FindSort;
sub _DebugString
{
    my($self,$str)=@_;
    my($package,$file,$line,$func)=caller(0);

    print STDERR "[$file][$func]:$line $str";
}


sub new
{
    my($class) =@_;
    my($self) = {};

    bless $self,$class;
    return $self;
}

sub SetCallBack($$@)
{
    my($self,$callfunc,@args)=@_;

    $self-> {_callfunc}=$callfunc;
    $self-> {_callargs}=[@args];
    return $self;
}

sub SetFilters($@)
{
    my($self,@filters)=@_;
    $self-> {_filters}=[@filters];
    return $self;
}

sub __SetError($$$)
{
    my($self,$exitcode,$msg)=@_;

    $self-> {_msg}=$msg;
    return $exitcode;
}

sub GetErrorMsg($)
{
    my($self)=@_;

    return defined($self-> {_msg}) ? $self-> {_msg} : ""
           ;
}

sub SetDir
{
	my ($self,$dir)=@_;

	if ($self->{_dir})
	{
		undef($self->{_dir});
	}
	$self->{_dir} = $dir;
	return $self;
}


sub ScanDirs($$)
{
    my($self,$dir)=@_;
    my(@filters);
    my(@fa,@dn);
    my($curdh,$curd,$curf,$curfilter);
    my(@curdirfiles,@curdirdirs,$cfsref,@sortfiles,@cfsarray);
    my($ret);
    $curd = $dir;
    $ret = opendir($curdh,$curd);
    if(! defined($ret))
    {
        return $self->__SetError(4,"can not open $curd $!");
    }

	@filters = ();
	
	if (defined($self->{_filters}))
	{
		@filters= @{$self->{_filters}}
	}
    while(1)
    {

NEXT_READ:
        while(($curf = readdir($curdh)))
        {
            if($curf eq "." ||
                    $curf eq "..")
            {
                next;
            }

            foreach $curfilter(@filters)
            {
                if($curf =~ /$curfilter/m)
                {
                    goto NEXT_READ;
                }
            }
            push(@curdirfiles,$curf);
        }

        closedir($curdh);
        undef($curdh);
        @sortfiles = sort(@curdirfiles);
        $cfsref = [@sortfiles];
        undef(@curdirfiles);

HANDLE_CFS:
        undef($fn);
        while(@ {$cfsref})
        {
            $curf = shift(@ {$cfsref});
            $fn = "$curd/$curf";
            if (defined($self->{_callfunc}))
            {
            	$ret = $self->{_callfunc}($dir,$fn,$curd,$curf,defined($self->{_callargs}) ? @{$self->{_callargs}} : ());
            	if ($ret < 0)
            	{
            		return $self->__SetError(6,"run callback in $fn($curf)");
            	}
            }
            
            if(-d $fn)
            {
# if we meet the dir ,just open it and read the dir
                last ;
            }
        }

        if(defined($fn) && -d $fn)
        {
            push(@cfsarray,$cfsref);
            push(@curdirdirs,$curd);
            $curd = $fn;
            $ret = opendir($curdh,$curd);
            if (!defined($ret))
            {
            	return $self->__SetError(4,"can not open $curd $!");
            }
# read the next one
            goto NEXT_READ;
        }
        else
        {
            undef($cfsref);
            $cfsref = pop(@cfsarray);
            $curd = pop(@curdirdirs);
            if(!defined($cfsref))
            {
                last;
            }
            goto HANDLE_CFS;
        }
    }

	return $self->__SetError(0,"");
}




1;
