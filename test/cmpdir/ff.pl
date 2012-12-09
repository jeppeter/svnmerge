#! perl

sub ErrorExit($$)
{
	my ($exitcode,$msg)=@_;
    my($pkg,$fn,$ln,$s)=caller(0);

    printf STDERR "[%-10s][%-20s][%-5d][INFO]:%s\n",$fn,$s,$ln,$msg;
	exit ($exitcode);
}

sub FindFile($@)
{
	my ($d,@filters)=@_;
	my (@fa,@dn);
	my ($curdh,$curd,$curf,$curfilter);
	my (@curdirfiles,@curdirdirs,$cfsref,@sortfiles,@cfsarray);

	$curd = $d;
	opendir($curdh,$curd) || ErrorExit(4,"can not open $curd");
	while(1)
	{
		
	NEXT_READ:
		while(($curf = readdir($curdh))  )
		{
			if ($curf eq "." ||
				$curf eq "..")
				{
					next;
				}
			$fn = "$curd/$curf";
			foreach $curfilter (@filters)
			{
				if ($curf =~ /$curfilter/m)
				{
					goto NEXT_READ;
				}
			}
			push(@curdirfiles,$fn);
		}

		closedir($curdh);
		undef($curdh);
		@sortfiles = sort(@curdirfiles);
		$cfsref = [@sortfiles];
		undef(@curdirfiles);

		HANDLE_CFS:
		while(@{$cfsref})
		{
			$curf = shift(@{$cfsref});
			$fn = "$curd/$curf";
			print STDOUT "$fn\n";
			if ( -d $fn )
			{
				# if we meet the dir ,just open it and read the dir
				last ;
			}
		}

		if (@{$cfsref} > 0)
		{
			$curd = $fn;
			push(@cfsarray,$cfsref);
			push(@curdirdirs,$curd);
			opendir($curdh,$curd) || ErrorExit(4,"can not open $curd $!");
			# read the next one
			goto NEXT_READ;
		}
		else
		{
			undef($cfsref);
			$cfsref = pop(@cfsarray);
			$curd = pop(@curdirdirs);
			if (!defined($cfsref))
			{
				last;
			}
			goto HANDLE_CFS;
		}
	}

	return ;
}

my ($d);
my (@filters);
push(@filters,"\\.git");
foreach $d (@ARGV)
{
	print STDOUT "Scan $d\n";
	FindFile($d,@filters);
}
