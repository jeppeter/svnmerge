#! perl -w

use Digest::SHA1;
use Data::Dumper;
use File::Find;

my @filters;
my @rawfiles;

sub DirFilter
{
    my ($curfile)=$_;
    my ($ret);
    $ret = 0;
    foreach (@filters)
    {
        my($curfilter)=$_;
        if ($File::Find::name =~ m/$curfilter/)
        {
            $ret = 1;
            last;
        }
    }
    if ($ret == 0)
    {
    	if ( (-f $File::Find::name) || ( -d $File::Find::name ))
        {
            push(@rawfiles,$File::Find::name);
        }
    }
}

sub TranslateFile($@)
{
    my ($fdir,@tmpfiles)=@_;
    my (@infiles);
    foreach(@tmpfiles)
    {
        my ($curfile)=$_;
        $curfile =~ s/\Q$fdir\E//;
        $curfile =~ s/^\///;
        push(@infiles,$curfile);
    }

    return @infiles;
}


sub DebugString($)
{
	my ($str) = @_;
	my ($pkg,$file,$line,$subroutine) =caller(0);

	print STDERR "In[$file:$line] $str";
}

sub CompareFileDigest($$)
{
	my ($orig,$new) = @_;
	my ($origsha,$newsha);
	my ($origfh,$newfh);
	my ($origdig,$newdig);


#	DebugString("Open $orig $new\n");
	open ($origfh," < $orig") ;
	open ($newfh,"< $new") ;

	$origsha = Digest::SHA1->new;
	$newsha = Digest::SHA1->new;

	$origsha->addfile(\$origfh);
	$newsha->addfile(\$newfh);

	$origdig = $origsha->b64digest;
	$newdig = $newsha->b64digest;

	close($origfh);
	close($newfh);
	if( $origdig eq $newdig)
	{
		return 0;
	}

	return 1;
}


sub FindDirFileExclude($@)
{
	my ($fdir,@exclude)=@_;
	my (@_ret) = ();
	@rawfiles=();
	@filters=@exclude;
	
	find(\&DirFilter,$fdir);
	# now to set for the 
	@_ret = @rawfiles;	
	return @_ret;
}

sub CompareFile($$)
{
	my ($aname,$bname)=@_;
	if ($aname eq $bname)
	{
		return 0;
	}
	elsif ($aname lt $bname)
	{
		return -1;
	}
	else
	{
		return 1;
	}
}



sub CompareFiles
{
	my ($reffiles,$refcmpfiles,$refnames,$refcmpnames)=@_;
	my (@files,@cmpfiles,@names,@cmpnames);
	my ($name_a,$name_b,$file_a,$file_b,$ret);

	@files=@$reffiles;
	@cmpfiles =@$refcmpfiles;
	@names = @$refnames;
	@cmpnames = @$refcmpnames;
#	DebugString("files: [@files] cmpfiles:[@cmpfiles]\n");
#	DebugString("names:[@names] cmpnames:[@cmpnames]\n");
	
	$name_a = pop @names;
	$name_b = pop @cmpnames;
	$file_a = pop @files;
	$file_b = pop @cmpfiles;
#	DebugString("files: [@files] cmpfiles:[@cmpfiles]\n");
#	DebugString("names:[@names] cmpnames:[@cmpnames]\n");
#	DebugString("namea $name_a nameb $name_b\n");
#	DebugString("filea $file_a fileb $file_b\n");
#	DebugString("namesize ".$#names."\n");
#	DebugString("cmpnamesize ".$#cmpnames."\n");
#	DebugString("filesize ".$#files."\n");
#	DebugString("cmpfilesize ".$#cmpfiles."\n");
	while(1)
	{
		if (!defined($name_a) || !defined($name_b))
		{
			
			if (defined($name_a))
			{
				#DebugString("name a $name_a\n");
			}

			if (defined($name_b))
			{
				#DebugString("name b $name_b\n");
			}
			last;
		}

		$ret = CompareFile($name_a,$name_b);
		if ($ret == 0)
		{
			# now to make digest 
			if ( -f $file_a &&  -f $file_b )
			{
			$ret = CompareFileDigest($file_a,$file_b);
			if ($ret != 0)
			{
				print STDOUT "M $name_a\n";
			}
}			
			elsif ( -d $file_a && -d $file_b)
			{
				;
			}
			else
			{
				print STDOUT "Not File $file_a <=> $file_b\n";
			}
			$name_a = pop @names;
			$name_b = pop @cmpnames;
			$file_a = pop @files;
			$file_b = pop @cmpfiles;			
		}
		elsif ($ret > 0)
		{
			print STDOUT "+ $name_a\n";
			$name_a = pop @names;
			$file_a = pop @files;
		}
		else 
		{
			print STDOUT "- $name_b\n";
			$name_b = pop @cmpnames;
			$file_b = pop @cmpfiles;
		}
	}

	if (defined($name_a))
	{
		print "+ $name_a\n";
	}

	while(@names)
	{		
		$name_a = pop @names;
		print "+ $name_a\n";
	}

	if (defined($name_b))
	{
		print STDOUT "- $name_b\n";
	}

	while(@cmpnames)
	{
		$name_b = pop @cmpnames;
		print STDOUT "- $name_b\n";
	}

	return ;
}


my ($dir) = shift @ARGV;
my ($cmpdir) = shift @ARGV;
my (@g_files) = FindDirFileExclude($dir,@ARGV);
my (@g_cmpfiles) = FindDirFileExclude($cmpdir,@ARGV);
my (@g_sortfiles) = sort  @g_files;
my (@g_sortcmpfiles) = sort  @g_cmpfiles;

@g_files=();
#print STDOUT "g_sortfiles\n";
#print Data::Dumper->Dump(\@g_sortfiles);
#print STDOUT "g_cmpsortfiles\n";
#print Data::Dumper->Dump(\@g_sortcmpfiles);
@g_files=TranslateFile($dir,@g_sortfiles);


#print STDOUT "g_sortfiles\n";
#print Data::Dumper->Dump(\@g_sortfiles);
#print STDOUT "g_cmpsortfiles\n";
#print Data::Dumper->Dump(\@g_sortcmpfiles);

@g_cmpfiles=();
@g_cmpfiles=TranslateFile($cmpdir,@g_sortcmpfiles);
#print STDERR "g_sortfiles\n";
#print STDERR Data::Dumper->Dump(\@g_sortfiles);
#print STDERR "g_sortcmpfiles\n";
#print STDERR Data::Dumper->Dump(\@g_sortcmpfiles);
#print STDERR "g_files\n";
#print STDERR Data::Dumper->Dump(\@g_files);
#print STDERR "g_cmpfiles\n";
#print STDERR Data::Dumper->Dump(\@g_cmpfiles);


CompareFiles(\@g_sortfiles,\@g_sortcmpfiles,\@g_files,\@g_cmpfiles);
