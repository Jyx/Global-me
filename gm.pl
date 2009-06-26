#!/usr/bin/perl
use strict;
use warnings;
use Cwd;
use File::Path;
use Digest::SHA  qw(sha1 sha1_hex sha1_base64);
use Benchmark;
use FindBin qw($Bin);

my $start = new Benchmark;

################################################################################
# User required settings.                                                      #
################################################################################
# 1. Set the bin_path to the folder where GNU global is installed.
#    Use forward slash since then it will work on both regular command prompt
#    and in a cygwin bash shell for example.
my $bin_path = "c:/cygwin/bin";

# 2. Set the drive where you want to store the GNU global databases.
my $drive_path = "c:";

# 3. Set the path to the folder where you want to store the individual database
#    This will be appended to the drive you set in step two above.
my $local_dbpath = "tmp/globaldb";

################################################################################
# Variables / paths                                                            #
################################################################################
my $debug = 0;

my $gtags = "$bin_path/gtags";
my $global = "$bin_path/global";
my $gtags_conf = "$bin_path/../share/gtags/gtags.conf";
$gtags_conf =~ s/\//\\/g;

my $command = "";

my $globaldb_path = "$drive_path/$local_dbpath";

my $script_dir = $Bin;
print "[DEBUG] script_dir: $script_dir\n" if $debug;

# Find out which perl/os version the client is using.
my $os = $^O;

# Store the current path.
my $source_path = &getcwd;

# Convert normal windows path to cygwin paths if needed.
if ($os =~ /cygwin/) {
	print "[DEBUG] running $os version of $0\n" if $debug;
	$drive_path = `cygpath -u $drive_path`;

	# This must be converted to a windows path since GNU global only
	# use normal windows path and not unix style paths.
	$source_path = `cygpath -w $source_path`;
	$bin_path = `cygpath -w $bin_path`;
} elsif ($os =~ /win32/i) {
	print "[DEBUG] running $os version of $0\n" if $debug;
	$source_path =~ s/\//\\/g;
	$bin_path =~ s/\//\\/g;
} else {
	print "Unsupported perl version.\n";
	exit;
}
chomp($drive_path);
chomp($source_path);
chomp($bin_path);

print "[DEBUG] source_path: $source_path\n" if $debug;

# Hash the path on the folder where the script is executed. Unfortunately
# the drive letter is uppercase for Win32 and lower case for cygwin, hence
# different hashes. This could be considered as a FIXME.
my $path_hash = sha1_hex($source_path);

# c:\tmp\globaldb\hash_xyz...
my $uniq_dbpath = "$globaldb_path/$path_hash";
mkpath("$uniq_dbpath");

# Update the global database path again, since we have the correct format on
# the $drive_path variable.
print "[DEBUG] globaldb_path: $globaldb_path\n" if $debug;

# For the same reason as source path, we must convert this to a normal windows
# path since it should be used as environment variable.
if ($os =~ /cygwin/) {
	$uniq_dbpath = `cygpath -w $uniq_dbpath`;
	chomp($uniq_dbpath);
} else {
	$uniq_dbpath =~ s/\//\\/g;
}


################################################################################
# Subroutines                                                                  #
################################################################################
sub is_gtags_existing {
	my $path = $_[0];
	my $ret = 0;
	if (-e "$path/GTAGS") {
		$ret = 1;
	}
	return $ret;
}

sub exec {
	my $cmd = $_[0];
	print "[DEBUG] Calling: $cmd\n" if $debug;
	print "[DEBUG]  from path: " . &getcwd . "\n" if $debug;
	my $res = `$cmd`;
}

################################################################################
# Main program                                                                 #
################################################################################
print "Collecting data for GNU global database (Windows version) ...\n";


$ENV{'GTAGSROOT'} = $source_path;
$ENV{'GTAGSDBPATH'} = $uniq_dbpath;
$ENV{'GTAGSCONF'} = $gtags_conf;

if (&is_gtags_existing($uniq_dbpath)) {
	&exec($global . " -u");
} else {
	$command = $gtags . " \"$uniq_dbpath\"";
	&exec($command);
}


# Write to file so the bat file can put this into environment variables.
my $bat_file = "$uniq_dbpath/env.bat";
open BATFILE, ">$bat_file" or die "$!\n";

if ($os =~ /cygwin/) {
	$bat_file = `cygpath -w $bat_file`;
	chomp($bat_file);
} else {
	$bat_file =~ s/\//\\/g;
}

# Create a bat file which sets everything up.
print BATFILE "echo off\n";
print BATFILE "set PATH=%PATH%;$bin_path\n";
print BATFILE "set GTAGSROOT=$ENV{'GTAGSROOT'}\n";
print BATFILE "set GTAGSDBPATH=$ENV{'GTAGSDBPATH'}\n";
print BATFILE "set GTAGSCONF=$ENV{'GTAGSCONF'}\n";
print BATFILE "$drive_path\n";
print BATFILE "cls\n";
print BATFILE "cd $source_path\n";
print BATFILE "echo Environment variables set, ready to use GNU Global.\n";
print BATFILE "echo.\n";
print BATFILE "echo Some simple global commands:\n";
print BATFILE "echo  global func1       show files that func1 is defined in.\n";
print BATFILE "echo  global -r func1    show files which func1 is referred from.\n";
print BATFILE "echo  global -x func1    show details about func1.\n";
print BATFILE "echo  global -a func1    gives absolute path name.\n";
print BATFILE "echo  global -s X        locate symbols not defined in GTAGS.\n";
print BATFILE "echo  global -g 'string' grep for 'string' in all files.\n";
print BATFILE "echo  global -f file     print functions in 'file'.\n";
print BATFILE "echo  global -c kmem     list all function beginning with 'kmem'.\n";
print BATFILE "echo.\n";
print BATFILE "cmd\n";
close BATFILE; 

my $end = new Benchmark;
my $diff = timediff($end, $start);
print "\nTime taken was ", timestr($diff, 'nop'), " seconds\n";
print "\nDone! To use the new database, please run the file:\n  $bat_file\n";





