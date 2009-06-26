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
# Executables                                                                  #
################################################################################
my $bin_path = "/usr/bin";
my $gtags = "$bin_path/gtags";
my $global = "$bin_path/global";

################################################################################
# Paths                                                                        #
################################################################################
my $script_dir = $Bin;

my $os = $^O;
my $os_path = "";

my $source_path = &getcwd;

# C: or /cygdrive/c
if ($os =~ /cygwin/) {
	$os_path = "/cygdrive/c";
	$source_path = `cygpath -w $source_path`;
	$bin_path = `cygpath -w $bin_path`;
} else {
	$os_path = "c:";
}
chomp($source_path);
chomp($bin_path);

# c:\tmp\globaldb
my $globaldb_path = "$os_path/tmp/globaldb";

# Hash the path on the folder where the script is executed.
my $path_hash = sha1_hex($source_path);

# c:\tmp\globaldb\hash_xyz...
my $uniq_dbpath = "$globaldb_path/$path_hash";
mkpath("$uniq_dbpath");


if ($os =~ /cygwin/) {
	$uniq_dbpath = `cygpath -w $uniq_dbpath`;
}

chomp($uniq_dbpath);

################################################################################
# Variables                                                                    #
################################################################################
my $debug = 0;
my $command = "";

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
	print "Calling: $cmd\n" if $debug;
	print "  from path: " . &getcwd . "\n" if $debug;
	my $res = `$cmd`;
}

################################################################################
# Main program                                                                 #
################################################################################
print "Collecting data for GNU global database (Windows version) ...\n";

$ENV{'GTAGSROOT'} = $source_path;
$ENV{'GTAGSDBPATH'} = $uniq_dbpath;
if (&is_gtags_existing($uniq_dbpath)) {
	&exec($global . " -u");
} else {
	$command = $gtags . " \"$uniq_dbpath\"";
}

&exec($command);

# Write to file so the bat file can put this into environment variables.
open ENVFILE, ">$script_dir/env.txt" or die "$!\n";
print "\nType following commands:\n";
print "  set PATH=%PATH%;$bin_path\n";
print "  set GTAGSROOT=$ENV{'GTAGSROOT'}\n";
print "  set GTAGSDBPATH=$ENV{'GTAGSDBPATH'}\n";
print ENVFILE "$ENV{'GTAGSROOT'}\n";
print ENVFILE "$ENV{'GTAGSDBPATH'}\n";
close ENVFILE;

open BATFILE, ">$script_dir/env.bat" or die "$!\n";
my $bat_file = `cygpath -w $script_dir/env.bat`;
print "\nor run the file:\n  $bat_file\n";
print BATFILE "set PATH=%PATH%;$bin_path\n";
print BATFILE "set GTAGSROOT=$ENV{'GTAGSROOT'}\n";
print BATFILE "set GTAGSDBPATH=$ENV{'GTAGSDBPATH'}\n";
close BATFILE; 

my $end = new Benchmark;
my $diff = timediff($end, $start);
print "\nTime taken was ", timestr($diff, 'nop'), " seconds\n";





