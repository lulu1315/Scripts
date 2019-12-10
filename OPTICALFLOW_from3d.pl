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
#debut ou fin de sequence
$FIRSTFRAME=$FSTART;
$LASTFRAME=$FEND;
$SHOT="";
$INDIR="$CWD/linetests";
$FORWARD3D="next";
$BACKWARD3D="prev";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/opticalflow";
$OUT_USE_SHOT=0;
$ZEROPAD=4;
$FORCE=0;
$EXT="exr";
$VERBOSE=0;
$DOFLOW=1;
$DOEXR=1;
$DORELIABLE=1;
$DOSEQUENTIAL=0;
$OFFSET=1;
#clean working dir
$CLEAN=1;
$CSV=0;
#log
$LOG1=" > /var/tmp/opticalflow3d.log";
$LOG2=" 2> /var/tmp/opticalflow3d.log";

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
open (AUTOCONF,">","3dflow_auto.conf");
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF "\$FIRSTFRAME=\$FSTART\;\n";
print AUTOCONF "\$LASTFRAME=\$FEND\;\n";
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(FORWARD3D);
print AUTOCONF confstr(BACKWARD3D);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(DOFLOW);
print AUTOCONF confstr(DOEXR);
print AUTOCONF confstr(DORELIABLE);
print AUTOCONF confstr(DOSEQUENTIAL);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
    print "-shot shotname\n";
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
    print "writing auto.conf : mv 3dflow_auto.conf 3dflow.conf\n";
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
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shotname : $SHOT\n";
    }
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad $ZEROPAD ...\n";
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
    print "force output ...\n";
    }
  }
  
$userName =  $ENV{'USER'}; 
  
if ($userName eq "dev18" || $userName eq "render")	#
  {
  $FLO2EXR="/shared/foss-18/FlowCode/build/flo2exr";
  $EXR2FLO="/shared/foss-18/FlowCode/build/exr2flo";
  $CONSISTENCYCHECK="/shared/foss-18/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/usr/bin/gmic";
  }

sub opticalflow {
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$INDIR/$SHOT";} else {$AUTODIR="$INDIR";}
    print ("frames $FSTART $FEND dir $AUTODIR\n");
    opendir DIR, "$AUTODIR";
    @images = grep { /$FORWARD3D/ && /$EXT/ } readdir DIR;
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
    $FIRSTFRAME=$min;
    $LASTFRAME=$max;
    print ("final seq    : $FSTART $FEND\n");
    print ("seq boundary : $FIRSTFRAME $LASTFRAME\n");
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    }
else
    {
    $OOUTDIR="$OUTDIR";
    }
    
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
if (-e "$OOUTDIR/dual") {print "$OOUTDIR/dual already exists\n";}
    else {$cmd="mkdir $OOUTDIR/dual";system $cmd;}
if (-e "$OOUTDIR/sequential") {print "$OOUTDIR/sequential already exists\n";}
    else {$cmd="mkdir $OOUTDIR/sequential";system $cmd;}
    
for ($i = $FSTART ;$i <= $FEND ;$i++)
{
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#
if ($i == $LASTFRAME) {$j=$i;} else {$j=$i+$OFFSET;} #cheat pour renderfarm
if ($i == $FIRSTFRAME) {$k=$i;} else {$k=$i-$OFFSET;} #cheat pour renderfarm

if ($ZEROPAD == 4)
    {
    $kk=sprintf("%04d",$k);
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$j);
    }
if ($ZEROPAD == 5)
    {
    $kk=sprintf("%05d",$k);
    $ii=sprintf("%05d",$i);
    $jj=sprintf("%05d",$j);
    }

if ($IN_USE_SHOT)
    {
    $FFOWARD3D="$INDIR/$SHOT/$FORWARD3D.$ii.$EXT";
    $BBACKWARD3D="$INDIR/$SHOT/$BACKWARD3D.$ii.$EXT";
    }
else
    {
    $FFOWARD3D="$INDIR/$FORWARD3D.$ii.$EXT";
    $BBACKWARD3D="$INDIR/$BACKWARD3D.$ii.$EXT";
    }

$FORWARD="$OOUTDIR/dual/forward_$ii\_$jj.flo";
$BACKWARD="$OOUTDIR/dual/backward_$ii\_$kk.flo";
$EXRFORWARD="$OOUTDIR/dual/forward_$ii\_$jj.exr";
$EXRBACKWARD="$OOUTDIR/dual/backward_$ii\_$kk.exr";

#sequential
$NEXT="$OOUTDIR/sequential/next.$ii.flo";
$PREV="$OOUTDIR/sequential/prev.$ii.flo";
$EXRNEXT="$OOUTDIR/sequential/next.$ii.exr";
$EXRPREV="$OOUTDIR/sequential/prev.$ii.exr";

#doshit
#$cmd="$GMIC $BBACKWARD3D -o $EXRBACKWARD";
$cmd="cp $BBACKWARD3D $EXRBACKWARD";
verbose $cmd;
system $cmd;
#$cmd="$GMIC $FFOWARD3D -o $EXRFORWARD";
$cmd="cp $FFOWARD3D $EXRFORWARD";
verbose $cmd;
system $cmd;
$cmd="$EXR2FLO $EXRBACKWARD $BACKWARD";
verbose $cmd;
system $cmd;
$cmd="$EXR2FLO $EXRFORWARD $FORWARD";
verbose $cmd;
system $cmd;
}

for ($i = $FSTART ;$i <= $FEND ;$i++)
{
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#
if ($i == $LASTFRAME) {$j=$i;} else {$j=$i+$OFFSET;} #cheat pour renderfarm
if ($i == $FIRSTFRAME) {$k=$i;} else {$k=$i-$OFFSET;} #cheat pour renderfarm

if ($ZEROPAD == 4)
    {
    $kk=sprintf("%04d",$k);
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$j);
    }
if ($ZEROPAD == 5)
    {
    $kk=sprintf("%05d",$k);
    $ii=sprintf("%05d",$i);
    $jj=sprintf("%05d",$j);
    }
$cmd="$CONSISTENCYCHECK $OOUTDIR/dual/backward_$jj\_$ii.flo $OOUTDIR/dual/forward_$ii\_$jj.flo $OOUTDIR/dual/reliable_$jj\_$ii.pgm $LOG1";
verbose($cmd);
print("--------> consistency backward [$jj->$ii]");
system $cmd;
#$cmd="$GMIC $OOUTDIR/dual/reliable_$jj\_$ii.pgm -o $OOUTDIR/dual/reliable_$jj\_$ii.png $LOG2";
#verbose($cmd);
#print(" [+convert to png]\n");
#system $cmd;

#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
print BOLD YELLOW "\nconverting $ii 3dflow took $hlat:$mlat:$slat \n";
print RESET;
}#end for $i
}#end opticalflow

#main
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
    $FIRSTFRAME=$FSTART;
    $LASTFRAME=$FEND;
    if ($process)
      {
      opticalflow();
      }
    }
   }
else
  {
  opticalflow();
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
