#!/usr/bin/perl
 
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
use POSIX qw/ceil/;
use List::Util qw[min max];
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

#defaults
$FSTART="auto";
$FEND="auto";
$FSTEP=1;
$ITERS=1;
$INTERVAL=10;
$SHOT="";
$IN_USE_SHOT=0;
$PROC_USE_SHOT=0;
$OUT_USE_SHOT=0;
$INDIR="$CWD/originales";
$IN="ima";
$PROCDIR="$CWD/intrinsics";
$PROC="ima";
$OUTDIR="$CWD/consistency";
$OUT="ima";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CLEAN=1;
#log
$LOG1=" > /var/tmp/opticalflow.log";
$LOG2=" 2> /var/tmp/opticalflow.log";

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

sub isnum ($) {
#returns 0 if string 1 if number
#http://www.perlmonks.org/?node=How%20to%20check%20if%20a%20scalar%20value%20is%20numeric%20or%20string%3F
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1
}

sub confstr {
#format lines for autoconf
  ($str) = @_;
  if (isnum(${$str}))
    {$line="\$$str=${$str}\;\n";}
  else
    {$line="\$$str=\"${$str}\"\;\n";}
  return $line;
  }

sub autoconf {
open (AUTOCONF,">","$scriptname\_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(ITERS);
print AUTOCONF confstr(INTERVAL);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(PROC_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(PROCDIR);
print AUTOCONF confstr(PROC);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: INTRINSICS_seq.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-iter iterations [1]\n";
	print "-f startframe endframe\n";
	print "-shot shot\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-procdir procdir\n";
	print "-p proc\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-zeropad4 [1]\n";
	print "-force [0]\n";
	print "-verbose";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf \n";
    autoconf();
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require "./$CONF";
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    }
  if (@ARGV[$arg] eq "-iter") 
    {
    $ITERS=@ARGV[$arg+1];
    print "iteration : $ITERS\n";
    }
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shot : $SHOT\n";
    $IN_USE_SHOT=1;
    $OUT_USE_SHOT=1;
    }
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
  if (@ARGV[$arg] eq "-i") 
    {
    $IN=@ARGV[$arg+1];
    print "image in : $IN\n";
    }
  if (@ARGV[$arg] eq "-procdir") 
    {
    $PROCDIR=@ARGV[$arg+1];
    print "processed dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-p") 
    {
    $PROC=@ARGV[$arg+1];
    print "processed : $IN\n";
    }
  if (@ARGV[$arg] eq "-odir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
  if (@ARGV[$arg] eq "-o") 
    {
    $OUT=@ARGV[$arg+1];
    print "image out : $OUT\n";
    }
  if (@ARGV[$arg] eq "-zeropad4") 
    {
    $ZEROPAD=1;
    print "zeropad4 ...\n";
    }
 if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    print "verbose ...\n";
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18")	#renderfarm
  {
  $CONSISTENCY="python3 /shared/foss-18/fast_blind_video_consistency/test_pretrained.py";
  }
  
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($PROC_USE_SHOT) {$AUTODIR="$PROCDIR/$SHOT";} else {$AUTODIR="$PROCDIR";}
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$PROC/ && /$EXT/ } readdir DIR;
    closedir DIR;
    $min=9999999;
    $max=-1;
    foreach $ima (@images) 
        { 
        #print ("$ima\n");
        @tmp=split(/\./,$ima);
        if ($#tmp >= 2)
            {
            $numframe=int($tmp[$#tmp-1]);
            #print ("$numframe\n");
            if ($numframe > $max) {$max = $numframe;}
            if ($numframe < $min) {$min = $numframe;}
            }
        }
    
    if ($FSTART eq "auto") {$FSTART = $min;}
    if ($FEND   eq "auto") {$FEND   = $max;}
    print ("auto  seq : $min $max\n");
    print ("final seq : $FSTART $FEND\n");
    }
  
if ($IN_USE_SHOT) {$IINDIR="$INDIR/$SHOT";} else {$IINDIR="$INDIR";}
if ($PROC_USE_SHOT) {$PPROCDIR="$PROCDIR/$SHOT";} else {$PPROCDIR="$PROCDIR";}
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else {$OOUTDIR="$OUTDIR";}
  
$pid=$$;
$WORKDIR="$OOUTDIR/w_$pid";
if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}

$LOOPS=(($FEND - $FSTART +1)/$INTERVAL);
$LLOOPS=ceil($LOOPS);
print ("loops : $LOOPS \n");
$OOUT="$OUT\_iter$ITERS";

for ($i = 0 ;$i < $LLOOPS;$i++)
{
    $FFSTART=($FSTART-1)+($i*$INTERVAL+1);
    $FFEND=min($FFSTART+$INTERVAL,$FEND);
    print ("i : $i s/e : $FFSTART/$FFEND \n");
    #forward consistency
    $PPROC=$PROC;
    $FSTEP=1;
    $OOOUT="forward";
    $cmd="$CONSISTENCY -original_dir $IINDIR -original_name $IN -processed_dir $PPROCDIR -processed_name $PPROC -output_dir $WORKDIR -output_name $OOOUT -fstart $FFSTART -fend $FFEND -fstep $FSTEP";
    verbose($cmd);
    system($cmd);
    #backward consistency
    $PPROC=$PROC;
    $FSTEP=-1;
    $OOOUT="backward";
    $cmd="$CONSISTENCY -original_dir $IINDIR -original_name $IN -processed_dir $PPROCDIR -processed_name $PPROC -output_dir $WORKDIR -output_name $OOOUT -fstart $FFEND -fend $FFSTART -fstep $FSTEP";
    verbose($cmd);
    system($cmd);
    
    for ($j = $FFSTART ;$j <= $FFEND;$j++)
    {
        $jj=sprintf("%04d",$j);
        #$BLEND=($j-($i*($INTERVAL))-1)/($FFEND-$FFSTART);
        $BLEND=($j-$FFSTART)/($FFEND-$FFSTART);
        $NBLEND=1-$BLEND;
        print ("$j blender : $BLEND\n");
        $cmd="gmic $WORKDIR/forward.$jj.$EXT $WORKDIR/backward.$jj.$EXT -mul[0] $NBLEND -mul[1] $BLEND -blend add -o $OOUTDIR/$OOUT.$jj.$EXT $LOG2";
        verbose($cmd);
        system($cmd);
    }
}

#for ($i = 1 ;$i <= $ITERS;$i++)
#{
#print ("iteration : $i\n");
#$j=$i-1;
#
#if ($i==1) 
#    {
#    $PPROC=$PROC;
#    $OOUT="$OUT\_iter$i";
#    $cmd="$CONSISTENCY -original_dir $IINDIR -original_name $IN -processed_dir $PPROCDIR -processed_name $PPROC -output_dir $OOUTDIR -output_name $OOUT -fstart $FSTART -fend $FEND -fstep $FSTEP";
#    verbose($cmd);
#    system($cmd);
#    } 
#else 
#    {
#    $PPROC="$OUT\_iter$j";
#    $OOUT="$OUT\_iter$i";
#    $cmd="$CONSISTENCY -original_dir $IINDIR -original_name $IN -processed_dir $OOUTDIR -processed_name $PPROC -output_dir $OOUTDIR -output_name $OOUT -fstart $FSTART -fend $FEND";
#    verbose($cmd);
#    system($cmd);
#    } 
#}

if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
