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

use DirTime;

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

sub ListDirTime($$@)
{
	my ($dir,$outfh,@filters)=@_;
	my ($ret);
	my ($fs);

	$fs = FindSort->new();
	$fs->SetDir($dir);
	$fs->SetFilters(@filters);
	$fs->SetCallBack(\&DirTimePrint,$outfh);
	$ret = $fs->ScanDirs($dir);
	return $ret;
}

sub DiffDirTime($$$@)
{
	my ($dir,$infh,$outfh,@filters)=@_;
	my ($dt);
	# now to
	$dt = DirTime->new();
	$dt->
}

