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

#defaults
$FSTART="auto";
$FEND="auto";
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$OUTDIR="$CWD/$scriptname";
$OUT="ima";
$FORCE=0;
$EXT="png";
$VERBOSE=0;
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#process params
$DOPREPAREDATA=1;
$DOOPTICALFLOW=1;
$DOSEGMENTATION=1;
#segmentation params
$FLOWWEIGHT=.2;
$TRESHOLD=.02;
$HIERARCHIES=40;

$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";

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
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#process\n";
print AUTOCONF confstr(DOPREPAREDATA);
print AUTOCONF confstr(DOOPTICALFLOW);
print AUTOCONF confstr(DOSEGMENTATION);
print AUTOCONF "#segmentation\n";
print AUTOCONF confstr(HIERARCHIES);
print AUTOCONF confstr(FLOWWEIGHT);
print AUTOCONF confstr(TRESHOLD);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
  print "usage: $scriptname \n";
      print "-f startframe endframe\n";
      print "-idir dirin\n";
      print "-i imagein\n";
      print "-odir dirout\n";
      print "-o imageout\n";
      print "-e image ext (png)\n";
      print "-size process xsize\n";
      print "-h hierarchies [40]\n";
      print "-force\n";
      exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf")
    {
    print "mv $scriptname\_auto.conf $scriptname.conf\n";
    autoconf();
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
  if (@ARGV[$arg] eq "-h")
    {
    $HIERARCHIES=@ARGV[$arg+1];
    print "hierarchies : $HIERARCHIES\n";
    }
 if (@ARGV[$arg] eq "-size")
    {
    $SIZE=@ARGV[$arg+1];
    print "process xsize : $SIZE\n";
    }
 if (@ARGV[$arg] eq "-force")
    {
    $FORCE=1;
    print "force output ...\n";
    }
 if (@ARGV[$arg] eq "-verbose")
    {
    $VERBOSE=1;
    $LOG="";
    print "force output ...\n";
    }
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $OFLOW_CLI="/shared/foss-18/hierarchical-graph-based-video-segmentation/build/optical_flow_cli/optical_flow_cli";
  $SEGMENT_CLI="/shared/foss-18/hierarchical-graph-based-video-segmentation/build/segment_cli/segment_cli";
  }
  
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$INDIR/$SHOT";} else {$AUTODIR="$INDIR";}
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$IN/ && /$EXT/ } readdir DIR;
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

#shot directories
if ($IN_USE_SHOT) {$IINDIR="$INDIR/$SHOT";}
else {$IINDIR="$INDIR/$SHOT";}
    
if ($OUT_USE_SHOT) {$OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else {$OOUTDIR="$OUTDIR";}
    
$DATADIR="$OOUTDIR/originales";
if ($DOPREPAREDATA)
{

if (-e "$DATADIR") {verbose("$DATADIR already exists");}
else {$cmd="mkdir $DATADIR";system $cmd;}

for ($i = $FSTART ;$i <= $FEND;$i++)
    {
    $ii=sprintf("%04d",$i);
    if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
    if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
    else {$GMIC2="";}
    if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} 
  $cmd="$GMIC -i $IINDIR/$IN.$ii.$EXT $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $DATADIR/$IN.$ii.$EXT $LOG2";
  verbose($cmd);
  print BOLD YELLOW "frame : $i ";print RESET;
  print("-> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
    }
}#end preparedata

$FLOWDIR="$OOUTDIR/flow";
if ($DOOPTICALFLOW)
{

if (-e "$FLOWDIR") {verbose("$FLOWDIR already exists");}
else {$cmd="mkdir $FLOWDIR";system $cmd;}
$cmd="$OFLOW_CLI --input-dir $DATADIR --output-dir $FLOWDIR";
verbose($cmd);
print BOLD YELLOW ("------------> processing opticalflow\n");print RESET;
system $cmd;
}#end doopticalflow

$VISDIR="$OOUTDIR/vis";
$SEGDIR="$OOUTDIR/segment";
if ($DOSEGMENTATION)
{
$LENGTH=$FEND-2;
$cmd="$SEGMENT_CLI --input-video $DATADIR --input-flow $FLOWDIR --length $LENGTH --flow-weight $FLOWWEIGHT --threshold $TRESHOLD --hierarchies $HIERARCHIES --vis-dir $VISDIR --output-dir $SEGDIR";
verbose($cmd);
print BOLD YELLOW ("------------> processing segmentation\n");print RESET;
system $cmd;
}
