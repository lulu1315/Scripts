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
$INDIR="$CWD/mask";
$IN="mask";
$GUIDEDIR="$CWD/guide";
$GUIDE="guide";
$OUTDIR="$CWD/$scriptname";
$OUT="ima";
$FORCE=0;
$EXTIN="png";
$EXT="png";
$VERBOSE=0;
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=0;
$BLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#process params
$GUIDEDRADIUS=5;
$GUIDEDREGULARIZATION=1e-6;
#postprocess
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOTRESHOLD=0;
$TRESHOLD=127;
$DOPOTRACE=0;
$POTRACEBLUR=3;
$BLACKLEVEL=.5;
$GPU=0;
$FORCE=0;
$CLEAN=1;
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
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(GUIDEDIR);
print AUTOCONF confstr(GUIDE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
#print AUTOCONF "#pre process\n";
#print AUTOCONF confstr(SIZE);
#print AUTOCONF confstr(DOLOCALCONTRAST);
#print AUTOCONF confstr(ROLLING);
#print AUTOCONF confstr(BLUR);
#print AUTOCONF confstr(BRIGHTNESS);
#print AUTOCONF confstr(CONTRAST);
#print AUTOCONF confstr(GAMMA);
#print AUTOCONF confstr(SATURATION);
print AUTOCONF "#process\n";
print AUTOCONF confstr(GUIDEDRADIUS);
print AUTOCONF confstr(GUIDEDREGULARIZATION);
print AUTOCONF "#post process\n";
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(DOTRESHOLD);
print AUTOCONF confstr(TRESHOLD);
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(POTRACEBLUR);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(FORCE);
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
      print "-radius : guided radius\n";
      print "-force\n";
      print "-gpu gpu_id [0]\n";
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
    
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$INDIR/$SHOT";} else {$AUTODIR="$INDIR";}
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$IN/ && /$EXTIN/ } readdir DIR;
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
    }
    
print ("final seq : $FSTART $FEND\n");

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
 if (@ARGV[$arg] eq "-radius")
    {
    $GUIDEDRADIUS=@ARGV[$arg+1];
    print "guided radius : $GUIDEDRADIUS\n";
    }
 if (@ARGV[$arg] eq "-gpu")
    {
    $GPU=@ARGV[$arg+1];
    print "gpu_id : $GPU\n";
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
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

#shot directories
if ($IN_USE_SHOT) {$IINDIR="$INDIR/$SHOT";}
else {$IINDIR="$INDIR";}

if ($IN_USE_SHOT) {$GGUIDEDIR="$GUIDEDIR/$SHOT";}
else {$GGUIDEDIR="$GUIDEDIR";}
    
if ($OUT_USE_SHOT) {$OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else {$OOUTDIR="$OUTDIR";}

$GUIDEDREGULARIZATION *= 255 * 255;

for ($i = $FSTART ;$i <= $FEND;$i++)
    {
    $ii=sprintf("%04d",$i);
    $cmd="$GMIC $IINDIR/$IN.$ii.$EXTIN $GGUIDEDIR/$GUIDE.$ii.$EXTIN -guided[0] [1],$GUIDEDRADIUS,$GUIDEDREGULARIZATION -remove[1] -cut 0,255 -fx_adjust_colors 0,$CONTRAST,$GAMMA,0,$SATURATION -o $OOUTDIR/$OUT.$ii.png $LOG2";
    verbose($cmd);
    print BOLD YELLOW "frame : $i ";print RESET;
    print("-> gmic guided filter [radius:$GUIDEDRADIUS regularization:$GUIDEDREGULARIZATION\n");
    system $cmd;
    if ($DOTRESHOLD)
        {
        $cmd="$GMIC $OOUTDIR/$OUT.$ii.png -ge $TRESHOLD -mul 255 -b 1 -o $OOUTDIR/$OUT\_treshold.$ii.png $LOG2";
        verbose($cmd);
        print("-> tresholding [treshold:$TRESHOLD\n");
        system $cmd;
        $cmd="$GMIC $OOUTDIR/$OUT\_treshold.$ii.png $GGUIDEDIR/$GUIDE.$ii.$EXTIN -guided[0] [1],5,$GUIDEDREGULARIZATION -remove[1] -cut 0,255 -fx_adjust_colors 0,$CONTRAST,$GAMMA,0,$SATURATION -o $OOUTDIR/$OUT\_treshold_guided.$ii.png $LOG2";
        verbose($cmd);
        print("-> gmic guided filter [radius:$GUIDEDRADIUS regularization:$GUIDEDREGULARIZATION\n");
        system $cmd;
        }
    }
