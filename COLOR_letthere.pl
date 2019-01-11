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
$OUTDIR="$CWD/colorletthere";
$OUT="ima";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$NETWORKSIZE=224;
$CLEAN=1;
$LOG="2>/var/tmp/letthere.log";

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
open (AUTOCONF,">","colorletthere_auto.conf");
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
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(NETWORKSIZE);
print AUTOCONF confstr(CLEAN);
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
      print "-zeropad4\n";
      print "-force\n";
      print "-networksize [224]\n";
      exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf")
    {
    print "writing auto.conf : mv colorletthere_auto.conf colorletthere.conf\n";
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
    $LOG="";
    print "force output ...\n";
    }
  if (@ARGV[$arg] eq "-networksize") 
    {
    $NETWORKSIZE=@ARGV[$arg+1];
    print "networksize : $NETWORKSIZE\n";
    }
  }

$userName =  $ENV{'USER'}; 
if ($userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  $TH="/shared/foss/torch-multi/install/bin/th";
  $LUA="/shared/foss/siggraph2016_colorization/colorize.lua";
  $MODEL="/shared/foss/siggraph2016_colorization/colornet.t7";
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $TH="/shared/foss-18/torch/install/bin/th";
  $LUA="/shared/foss/siggraph2016_colorization/colorize.lua";
  $MODEL="/shared/foss/siggraph2016_colorization/colornet.t7";
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
    
for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
#preprocess
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    }

if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    }
else
    {
    $OOUTDIR=$OUTDIR;
    }
    
if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}
if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
else {$cmd="mkdir $OOUTDIR";system $cmd;}
$OOUT="$OOUTDIR/$OUT.$ii.$EXT";

$WORKDIR="$OOUTDIR/w$ii";
$NETWORK="$WORKDIR/network.$ii.$EXT";
$COLORIMA="$WORKDIR/color.$ii.$EXT";

if (-e $OOUT && !$FORCE)
{print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  print BOLD YELLOW "processing frame $ii\n";print RESET;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  $resizecmd="$GMIC -i $IIN -resize2dx $NETWORKSIZE,5 -o $NETWORK $LOG";system $resizecmd;
  $colorcmd="$TH $LUA $NETWORK $COLORIMA $MODEL";verbose($colorcmd);system $colorcmd;
  $combinecmd="$GMIC -i $IIN $COLORIMA \\
    -rgb2yuv8[1] -resize[1] [0],5 \\
    -channels[0] 0 -channels[1] 1,2 \\
    -split[1] c -append c -yuv82rgb -o $OOUT $LOG";system $combinecmd;
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat !\n\n";print RESET;
  #-----------------------------#
  }
}

#-------------------------------------------------------#
#---------gestion des timecodes ------------------------#
#-------------------------------------------------------#
sub hmstoglob {
my ($s,$m,$h) = @_;
my $glob;
#
$glob=$s+60*$m+3600*$h;
return $glob;
}
sub globtohms {
my ($glob) = @_;
my $floath=$glob/3600;
my $h=int($floath);
#
my $reste=$glob-3600*$h;
my $floatm=$reste/60;
my $m=int($floatm);
#
my $s=$glob-3600*$h-60*$m;
#
return ($s,$m,$h);
}
sub timeplus  {
#($s,$m,$h)=timeplus($s1,$m1,$h1,$s2,$m2,$h2)
      my ($s1,$m1,$h1,$s2,$m2,$h2) = @_;
      $glob1=hmstoglob($s1,$m1,$h1);
      $glob2=hmstoglob($s2,$m2,$h2);
      $glob=$glob1+$glob2;
      ($s,$m,$h) =globtohms($glob);
      return ($s,$m,$h);
}
sub lapse  {
#($s,$m,$h)=lapse($s1,$m1,$h1,$s2,$m2,$h2)
      my ($s1,$m1,$h1,$s2,$m2,$h2) = @_;
      $glob1=hmstoglob($s1,$m1,$h1);
      $glob2=hmstoglob($s2,$m2,$h2);
      if ($glob1 > $glob2)
              {
              $glob1=86400-$glob1;
              $glob=$glob2+$glob1;
              }
              else
              {
              $glob=$glob2-$glob1;
              }
#     print "$glob1 $glob2 $glob \n";
      my ($s,$m,$h) =globtohms($glob);
      return ($s,$m,$h);
}
