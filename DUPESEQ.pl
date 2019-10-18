#!/usr/bin/perl
 
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$HOSTNAME=`cat /etc/hostname`;chop $HOSTNAME;
$KDEVERSION=`lsb_release -c -s`;chop $KDEVERSION;
$GPUS=`nvidia-smi -L | wc -l`;chop $GPUS;
$GPUTYPE=`nvidia-smi -q -i 0 | grep "Product Name" | cut -d':' -f2 | cut -c 2-`;chop $GPUTYPE;
$script = $0;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
$userName =  $ENV{'USER'}; 
print BOLD BLUE "----------------------\n";print RESET;
print BOLD BLUE "user    : $userName\n";print RESET;
print BOLD BLUE "host    : $HOSTNAME\n";print RESET;
print BOLD BLUE "kde     : $KDEVERSION\n";print RESET;
print BOLD BLUE "gpu     : $GPUTYPE (x$GPUS)\n";print RESET;
print BOLD BLUE "script  : $scriptname\n";print RESET;
print BOLD BLUE "project : $PROJECT\n";print RESET;
print BOLD BLUE "----------------------\n";print RESET;
$pid=$$;

#defaults
$FSTART=1;
$FEND=100;
$INDIR="$CWD/originales";
$OUTDIR="$CWD/originales";
$IN="ima";
$ZEROPAD=1;
$EXT="png";
$VERBOSE=1;
$TRESHOLD=100;
$METHOD=2;
$LOG1=" > /var/tmp/dupseq.log";
$LOG2=" 2> /var/tmp/dupseq.log";

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}
sub warning {
    if ($VERBOSE) {print BOLD RED "@_\n";print RESET}
}
sub info {
    if ($VERBOSE) {print BOLD BLUE "@_\n";print RESET}
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-f startframe endframe\n";
	print "-idir dirin\n";
    print "-odir dirout\n";
	print "-i imagein\n";
	print "-treshold [100]\n";
    print "-method [2]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print "seq : $FSTART $FEND\n";
    }
  if (@ARGV[$arg] eq "-idir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-odir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
  if (@ARGV[$arg] eq "-i") 
    {
    $IN=@ARGV[$arg+1];
    print "image in : $IN\n";
    }
  if (@ARGV[$arg] eq "-treshold") 
    {
    $TRESHOLD=@ARGV[$arg+1];
    print "treshold $TRESHOLD\n";
    }
  if (@ARGV[$arg] eq "-method") 
    {
    $METHOD=@ARGV[$arg+1];
    print "methode $METHOD\n";
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "lulu" || $userName eq "dev" || $userName eq "render")	#
  {
  $DUPE="/usr/bin/findimagedupes";
  $GMIC="/usr/bin/gmic";
  $AVERAGE="python /shared/Scripts/python/average.py";
  }
if ($userName eq "dev18")	#
  {
  $DUPE="/usr/bin/findimagedupes";
  $GMIC="/usr/bin/gmic";
  $AVERAGE="python3 /shared/Scripts/python/average.py";
  }
#$INDIR =~ s/\///;    
#$OUTDIR="$INDIR/dupes";
#$cmd="mkdir $OUTDIR";
#print "$cmd\n";
#system $cmd;

$nodupecount=1;
$minaverage=999999;
$minaverageframe=$FSTART;
for ($i = $FSTART ;$i <= $FEND;$i++)
{
verbose("checking : frame $i");
$j=$i+1;
$ii=sprintf("%04d",$i);
$jj=sprintf("%04d",$j);
$A="$INDIR/$IN.$ii.$EXT";
$B="$INDIR/$IN.$jj.$EXT";

if ($METHOD == 1)
    {
    $cmd="$DUPE -t=$TRESHOLD% $A $B";
    $log=`$cmd`;
    #print("$cmd\n");
    #verbose($log);
    if ($log ne "")
        {
        chop $log;
        @tmp=split(/ /,$log);
        $DUPEFRAME=@tmp[1];
        $cmd="mv $DUPEFRAME $OUTDIR";
        verbose($cmd);
        #system $cmd;
        $i++;
        }
    }
if ($METHOD == 2)
    {
    $cmd="$GMIC $A $B sub abs -o tmp_$pid.png $LOG2";
    system $cmd;
    $cmd="$AVERAGE -i tmp_$pid.png";
    $average=`$cmd`;
    chop $average;
    #print("$cmd\n");
    if ($average <= 1) {warning("average difference: $average");}
    else {verbose("average difference: $average");}
    if ($average <= $TRESHOLD)
        {
        #$cmd="mv $A $OUTDIR";
        info("average diff : $average");
        #system $cmd;
        }
    else
        {
        $nodupe=sprintf("%04d",$nodupecount);
        $cmd="cp $A $OUTDIR/$IN\_nodupe.$nodupe.$EXT";
        info("$cmd");
        system $cmd;
        $nodupecount++;
        if ($average < $minaverage) {$minaverage = $average;$minaverageframe=$i;}
        }
    }
}

verbose("min accepted average = $minaverage for frame $minaverageframe\n");
