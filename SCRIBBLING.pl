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
$FSTEP=1;
$SHOT="";
$STIPPLEDIR="$CWD/stippling";
$MINSIZE=1;
$MAXSIZE=6;
$STIPPLE="ima_min\$MINSIZE\\_max\$MAXSIZE";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/scribbling";
$OUT="ima";
$OUT_USE_SHOT=0;
#messy parameters
$MAXCOUNT=200;
$DOPIXELFORCE=1;
$PIXELINFLUENCE=10;
$MINPIXFORCE=0;
$HALFPERCEPTION=2;
$DOGRADIENTFORCE=0;
$GRADIENTBLUR=5;
$GRADIENTINFLUENCE=0;
$DOTANGENTFORCE=0;
$TANGENTINFLUENCE=1;
$DRAGINFLUENCE=0;
$DONOISEFORCE=1;
$DOCURLNOISE=0;
$NOISEINFLUENCE=2;
$ZSTEP=.01;
$NOISETYPE=4;
$NOISEFREQUENCY=.05;
$DOBOUNDFORCE=0;
$BOUND=80;
$BOUNDFORCEFACTOR=0;
$COLINEARLIMIT=.9999;
$MAXSPEED=1000;
$LINEOPACITY=.5;
$COLORPOWER=3;
$LINEWIDTHMIN=0;
$LINEWIDTHMAX=6;
$SPLINESTEP=.01;
$OVERSAMPLING=2;
$OUTPUTSIZEX=1920;
$DEBUG=0;
#
$DOLOCALCONTRAST=1;
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CLEAN=1;
$CSV=0;
$LOG1=">/var/tmp/scribble.log";
$LOG2="2>/var/tmp/scribble.log";
#JSON
$CAPACITY=500;
$SKIP="-force";
$FPT=5;
$PARAMS="_stroke\$MAXCOUNT\\_pixinf\$PIXELINFLUENCE";

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
open (AUTOCONF,">","scribbling_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(STIPPLEDIR);
print AUTOCONF confstr(MINSIZE);
print AUTOCONF confstr(MAXSIZE);
print AUTOCONF confstr(STIPPLE);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(OUT_USE_SHOT);
#messy parameters
print AUTOCONF confstr(MAXCOUNT);
print AUTOCONF confstr(DOPIXELFORCE);
print AUTOCONF confstr(PIXELINFLUENCE);
print AUTOCONF confstr(MINPIXFORCE);
print AUTOCONF confstr(HALFPERCEPTION);
print AUTOCONF confstr(DOGRADIENTFORCE);
print AUTOCONF confstr(GRADIENTBLUR);
print AUTOCONF confstr(GRADIENTINFLUENCE);
print AUTOCONF confstr(DOTANGENTFORCE);
print AUTOCONF confstr(TANGENTINFLUENCE);
print AUTOCONF confstr(DRAGINFLUENCE);
print AUTOCONF confstr(DONOISEFORCE);
print AUTOCONF confstr(DOCURLNOISE);
print AUTOCONF confstr(NOISEINFLUENCE);
print AUTOCONF confstr(ZSTEP);
print AUTOCONF confstr(NOISETYPE);
print AUTOCONF confstr(NOISEFREQUENCY);
print AUTOCONF confstr(DOBOUNDFORCE);
print AUTOCONF confstr(BOUND);
print AUTOCONF confstr(BOUNDFORCEFACTOR);
print AUTOCONF confstr(COLINEARLIMIT);
print AUTOCONF confstr(MAXSPEED);
print AUTOCONF confstr(LINEOPACITY);
print AUTOCONF confstr(COLORPOWER);
print AUTOCONF confstr(LINEWIDTHMIN);
print AUTOCONF confstr(LINEWIDTHMAX);
print AUTOCONF confstr(SPLINESTEP);
print AUTOCONF confstr(OVERSAMPLING);
print AUTOCONF confstr(OUTPUTSIZEX);
print AUTOCONF confstr(DEBUG);
print AUTOCONF confstr(DOLOCALCONTRAST);
#
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(PARAMS);
print AUTOCONF "1\n";
close AUTOCONF;
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-zeropad [4]\n";
	print "-force [0]\n";
	print "-verbose\n";
    print "-csv csv_file.csv\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
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
  if (@ARGV[$arg] eq "-step") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "step $FSTEP\n";
    }
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad : $ZEROPAD\n";
    }
 if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose on\n";
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $SCRIBBLE="/shared/foss-18/MessyCurves/build/stipplecurves";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}
$pid=$$;

sub csv {
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
    
for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
{
#
if ($ZEROPAD == 4) {$ii=sprintf("%04d",$i);}
if ($ZEROPAD == 5) {$ii=sprintf("%05d",$i);}
#
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    #$INPLY="$STIPPLEDIR/$SHOT/$STIPPLE.$ii.ply";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    #$INPLY="$STIPPLEDIR/$STIPPLE.$ii.ply";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $OOUT="$OOUTDIR/$OUT$PARAMS.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    $OOUT="$OUTDIR/$OUT$PARAMS.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
    
$INPLY="$STIPPLEDIR/$SHOT/$STIPPLE.$ii.ply";
#working dir
$WORKDIR="$OOUTDIR/w$ii\_$pid";
#work frames
$WINPUT="$WORKDIR/preprocess.$EXT";

if (-e $OOUT && !$FORCE)
   {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else {
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #touch file
  $touchcmd="touch $OOUT";
  if ($VERBOSE) {print "$touchcmd\n";}
  #verbose($touchcmd);
  system $touchcmd;
  #
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #
  if ($DOLOCALCONTRAST) 
    {$GMIC1="-fx_normalize_local 2,6,5,40,1,11,0,50,50";} else {$GMIC1="";}
  $cmd="$GMIC -i $IIN $GMIC1 -o $WINPUT $LOG2";
  print("--------> preprocess [lce:$DOLOCALCONTRAST]\n");
  verbose($cmd);
  system $cmd;
  #scribble
  $cmd="$SCRIBBLE $INPLY $WINPUT $OOUT $MAXCOUNT $DOPIXELFORCE $PIXELINFLUENCE $MINPIXFORCE $HALFPERCEPTION $DOGRADIENTFORCE $GRADIENTBLUR $GRADIENTINFLUENCE $DOTANGENTFORCE $TANGENTINFLUENCE $DRAGINFLUENCE $DONOISEFORCE $DOCURLNOISE $NOISEINFLUENCE $ZSTEP $NOISETYPE $NOISEFREQUENCY $DOBOUNDFORCE $BOUND $BOUNDFORCEFACTOR $COLINEARLIMIT $MAXSPEED $LINEOPACITY $COLORPOWER $MINSIZE $MAXSIZE $LINEWIDTHMIN $LINEWIDTHMAX $SPLINESTEP $OVERSAMPLING $OUTPUTSIZEX $DEBUG";
  verbose($cmd);
  system $cmd;
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "Writing  SCRIBBLING $ii took $hlat:$mlat:$slat \n\n";print RESET;
  #-----------------------------#
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  }
}#end imageloop
}#end csv

if ($CSV)
  {
  open (CSV , "$CSVFILE");
  while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $SHOT=@line[0];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    if ($process)
      {
      csv();
      }
    }
   }
else
  {
  csv();
  }


#-------------------------------------------------------#
#---------gestion des timecodes ------------------------#
#-------------------------------------------------------#
sub hmstoglob	{
my ($s,$m,$h) = @_;
my $glob;
#
$glob=$s+60*$m+3600*$h;
return $glob;
}

sub globtohms	{
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
#	print "$glob1 $glob2 $glob \n";
	my ($s,$m,$h) =globtohms($glob);
	return ($s,$m,$h);
}
