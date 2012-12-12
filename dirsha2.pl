#! perl

####################################
#
#             this file is the second full fill of dirsha
#             copyright@2012-2030  
#             it is according to the GPLv2 license
#
#             this file is to use the sequence of findsort.pm
#             this will give the scan directory once
#
#             this file is to make the time compare for the job
#
#             this file is the test one
#             if you have any question ,please send email to <jeppeter#gmail.com>
#
####################################

use threads;
use threads::shared;
use Time::HiRes qw(usleep);


# now to handle the time function
sub DirTimePrint($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	my ($relativefname,$tfname);
	my ($fh)=@args;
	my (@sts,$mtime);
	$tfname = $fname;
	$fname =~ s/^\Q$dir\E[\/\\]+//;

	$relativefname = $fname;
	if ( -d $tfname )
	{
		# if directory ,not give any of time
		print $fh  "F $relativefname\n";
	}
	elsif ( -f $tfname )
	{
		# only file to print time
		@sts = stat($tfname);
		if (@sts <= 0)
		{
			return -3;
		}

		# that is ok
		$mtime = $sts[9];
		print $fh "F $relativefname\n";
		print $fh "T $mtime\n";
	}	
	return 0;
}

sub DirTimePush($$$$@)
{
	my ($dir,$fname,$curd,$pname,@args)=@_;
	my ($href)=@args;
	my ($aref);
	my ($relativefname,$tfname);
	my (@sts,$mtime);

	$tfname = $fname;
	$fname =~ s/^\Q$dir\E[\/\\]+//;
	$relativefname = $fname;

	{
		# now to push the file
		lock($href);
		$aref = $href->{_array};
		push(@{$aref},$relatetivefname);
	}
	return 0;
}

sub GetFileNameFromArray($)
{
	my ($href)=@_;
	my (@retarr,$isended,$aref);
	
	@retarr = ();
	$isended = 0;
	do
	{
		{
			lock($href);
			$aref = $href->{_array};
			@retarr = @{$aref};
			$isended = $href->{_ended};
		}

		if ($isended == 0 && @retarr == 0)
		{
			usleep(1000);
		}
	}while((@retarr == 0) && $isened == 0);

	return @retarr;
}

sub GetNextFile($)
{
	my ($href)=@_;
	my (@getarr,$aref,$getf);
	
try_again:
	$aref = $href->{_stored};
	$getf = shift(@{$aref});
	if (defined($getf))
	{
		# just get the name
		$href->{_getf} = $getf;
		return $getf;
	}

	# now to get from the 
	@getarr = GetFileNameFromArray($href);
	if (@getarr > 0)
	{
		$href->{_stored} = [@getarr];
		goto try_again;
	}
	undef($href->{_getf});
	return undef;
}

sub GetCurFile($)
{
	my ($href)=@_;

	# we should get next for the first time
	return defined($href->{_getf}) ? $href->{_getf} : GetNextFile($href);
}
