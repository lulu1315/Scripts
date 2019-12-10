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
$CONTINUE=-1;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/stippling";
$OUT="ima";
$OUT_USE_SHOT=0;
$FLOWMODE=1;
$FLOWDIR="$CWD/opticalflow";
$SIZE=0;
#preprocess
$ROLLING=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOLOCALCONTRAST=1;
$LINEARIZE=0;
$EQUALIZE=0;
#reindex result
$DOINDEX=0;
$INDEXCOLOR=8;
$INDEXMETHOD=1;
$DITHERING=1;
$INDEXROLL=5;
#stippling parameters
$INITIALPOINTS=1;
$INITIALPOINTSIZE=4;
$ADAPTATIVEPOINTSIZE=1;
$POINTSIZEMIN=1;
$POINTSIZEMAX=12;
$SUPERSAMPLINGFACTOR=1;
$MAXITERATIONS=1000;
$HYSTERESIS=.6;
$HYSTERESISDELTA=.01;
$HYSTERESISSTRATEGY=8;
$STIPPLESIZEFACTOR=2.5;
#misc
$PARAMS="_min\$POINTSIZEMIN\\_max\$POINTSIZEMAX";
$CSVFILE="./SHOTLIST.csv";
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CLEAN=1;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#JSON
$CAPACITY=500;
$SKIP="-force";
$FPT=5;

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
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(FLOWMODE);
print AUTOCONF "#flowmode\n";
print AUTOCONF "#0:no optical flow 1:computed backward\n";
#print AUTOCONF "#1:precomputed backward 2:precomputed forward\n";
#print AUTOCONF "#3:computed backward 4:computed forward\n";
#print AUTOCONF confstr(FLOWDIR);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(LINEARIZE);
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF "#reindex\n";
print AUTOCONF confstr(DOINDEX);
print AUTOCONF confstr(INDEXCOLOR);
print AUTOCONF confstr(INDEXMETHOD);
print AUTOCONF confstr(DITHERING);
print AUTOCONF confstr(INDEXROLL);
print AUTOCONF "#stippleparams\n";
print AUTOCONF confstr(INITIALPOINTS);
print AUTOCONF confstr(INITIALPOINTSIZE);
print AUTOCONF confstr(ADAPTATIVEPOINTSIZE);
print AUTOCONF confstr(POINTSIZEMIN);
print AUTOCONF confstr(POINTSIZEMAX);
print AUTOCONF confstr(SUPERSAMPLINGFACTOR);
print AUTOCONF confstr(MAXITERATIONS);
print AUTOCONF confstr(HYSTERESIS);
print AUTOCONF confstr(HYSTERESISDELTA);
print AUTOCONF confstr(HYSTERESISSTRATEGY);
print AUTOCONF "#strategy = 0 reset hysteresis for each frame\n";
print AUTOCONF "#strategy = 1 use fix finalhysteresis for advected frame\n";
print AUTOCONF "#strategy >= 2 rewind finalhysteresis towards initial hysteresis\n";
print AUTOCONF confstr(STIPPLESIZEFACTOR);
print AUTOCONF "#divider for point size in image only\n";
print AUTOCONF "#misc\n";
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
#print AUTOCONF confstr(OFFLINE);
print AUTOCONF confstr(PARAMS);
print AUTOCONF "1\n";
close AUTOCONF;
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-step step[1]\n";
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
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print BOLD BLUE "configuration file : $CONF\n";print RESET;
    require "./$CONF";
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
    }
  if (@ARGV[$arg] eq "-f") 
    {
    $FSTART=@ARGV[$arg+1];
    $FEND=@ARGV[$arg+2];
    print BOLD BLUE "seq : $FSTART $FEND\n";print RESET;
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
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shot $SHOT\n";
    }
 if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
  if (@ARGV[$arg] eq "-continue") 
    {
    $CONTINUE=@ARGV[$arg+1];
    print "continuing at frame : $CONTINUE\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
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
  $STIPPLING="/shared/foss-18/LindeBuzoGrayStippling/build/LBGStippling";
  }
  
sub stippling {

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
    
if ($FSTART eq "csv" || $FEND eq "csv")
    {
    open (CSV , "$CSVFILE");
    while ($line=<CSV>)
        {
        chop $line;
        @line=split(/,/,$line);
        $CSVSHOT=@line[0];
        $CSVFSTART=@line[3];
        $CSVFEND=@line[4];
        if ($CSVSHOT eq $SHOT)
            {
            if ($FSTART eq "csv") {$FSTART = $CSVFSTART;}
            if ($FEND   eq "csv") {$FEND   = $CSVFEND;}
            last;
            } 
        }
    print ("csv   seq : $CSVFSTART $CSVFEND\n");
    print ("final seq : $FSTART $FEND\n");
    }
    
if ($CONTINUE == -1) {$CONTINUE = $FSTART};

$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

$pid=$$;
      
for ($i=$CONTINUE ; $i <= $FEND ; $i=$i+$FSTEP)
{
if ($ZEROPAD == 4)
    {
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$i-1);
    $kk=sprintf("%04d",$i+1);
    }
if ($ZEROPAD == 5)
    {
    $ii=sprintf("%05d",$i);
    $jj=sprintf("%05d",$i-1);
    $kk=sprintf("%05d",$i+1);
    }
    
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    $JJN="$INDIR/$SHOT/$IN.$jj.$EXT";
    $KKN="$INDIR/$SHOT/$IN.$kk.$EXT";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    $JJN="$INDIR/$IN.$jj.$EXT";
    $KKN="$INDIR/$IN.$kk.$EXT";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $OOUT="$OOUTDIR/$OUT$PARAMS.$ii.png";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    $OOUT="$OUTDIR/$OUT$PARAMS.$ii.png";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }

#oflow
#if ($FLOWMODE == 1) {$OFLOW="$FLOWDIR/$SHOT/dual/backward_$ii\_$jj.flo"};
#if ($FLOWMODE == 2) {$OFLOW="$FLOWDIR/$SHOT/dual/forward_$jj\_$ii.flo"};
#working dir
$WORKDIR="$OOUTDIR/w$ii\_$pid";
#work frames
$WINPUT     ="$WORKDIR/preprocess.$EXT";
$WPREV      ="$WORKDIR/previous.$EXT";
$WCUR       ="$WORKDIR/current.$EXT";
$WNEXT      ="$WORKDIR/next.$EXT";

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
  print BOLD BLUE ("\nframe : $ii\n");print RESET;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
#preprocessing input
  if ($SIZE != 0) 
    {$GMIC0="-resize2dx $SIZE,5";} else {$GMIC0="";}
  if ($ROLLING != 0) 
    {$GMIC1="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC1="";}
  if (($BRIGHTNESS != 0) || ($CONTRAST != 0) || ($GAMMA != 0) || ($SATURATION != 0)) 
    {$GMIC2="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC2="";}
  if ($DOLOCALCONTRAST) 
    #{$GMIC3="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC3="";}
    {$GMIC3="-fx_normalize_local 2,6,5,40,1,11,0,50,50";} else {$GMIC3="";}
  if ($LINEARIZE) 
    {$GMIC4="-srgb2rgb";} else {$GMIC4="";}
  if ($EQUALIZE) 
    {$GMIC5="-equalize 256,1%,99%";} else {$GMIC5="";}
  $cmd="$GMIC -i $IIN $GMIC0 $GMIC1 $GMIC5 $GMIC3 $GMIC4 $GMIC2 -cut 0,255 -o $WINPUT $LOG2";
  print("--------> preprocess [resize: $SIZE blur:$CONTENTBLUR b/c/g/s:$BRIGHTNESS,$CONTRAST,$GAMMA,$SATURATION lce:$DOLOCALCONTRAST equalize:$EQUALIZE linearize:$LINEARIZE]\n");
  verbose($cmd);
  system $cmd;
  if ($DOINDEX)
        {
        $cmd="$GMIC $WINPUT --colormap $INDEXCOLOR,$INDEXMETHOD,1 -index[0] [1],$DITHERING,1 -remove[1] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WINPUT $LOG2";
        verbose($cmd);
        print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
        system $cmd;
        }
            
  if ($i == $FSTART || $FLOWMODE == 0)
    {
    $stipplecmd="$STIPPLING $WINPUT $OOUTDIR/$OUT$PARAMS.$ii $INITIALPOINTS $INITIALPOINTSIZE $ADAPTATIVEPOINTSIZE $POINTSIZEMIN $POINTSIZEMAX $SUPERSAMPLINGFACTOR $MAXITERATIONS $HYSTERESIS $HYSTERESISDELTA $STIPPLESIZEFACTOR 0 0 $i";
    verbose($stipplecmd);
    system $stipplecmd;
    }
  else
    {
    #resize previous frame if necessary
    if ($SIZE != 0) 
        {
        $cmd="$GMIC -i $JJN -resize2dy $SIZE,5 -cut 0,255 -o $WPREV $LOG2";
        print("--------> resize previous frame\n");
        verbose($cmd);
        system $cmd;
        $cmd="$GMIC -i $IIN -resize2dy $SIZE,5 -cut 0,255 -o $WCUR $LOG2";
        print("--------> resize current frame\n");
        verbose($cmd);
        system $cmd;
        if ($i == $FEND) {
            $cmd="cp $WCUR $WNEXT";
            print("--------> last frame ... copy current\n");
        }
        else {
            $cmd="$GMIC -i $KKN -resize2dy $SIZE,5 -cut 0,255 -o $WNEXT $LOG2";
            print("--------> resize next frame\n");
        }
        verbose($cmd);
        system $cmd;
        }
    else
        {
        $cmd="cp $IIN $WCUR;cp $JJN $WPREV;cp $KKN $WNEXT";
        verbose($cmd);
        system $cmd;
        }
#    if ($FLOWMODE == 1 || $FLOWMODE == 2)
#        {
#        $stipplecmd="$STIPPLING $WINPUT $OOUTDIR/$OUT$PARAMS.$ii $INITIALPOINTS $INITIALPOINTSIZE $ADAPTATIVEPOINTSIZE $POINTSIZEMIN $POINTSIZEMAX $SUPERSAMPLINGFACTOR $MAXITERATIONS $HYSTERESIS $HYSTERESISDELTA $STIPPLESIZEFACTOR $FLOWMODE $HYSTERESISSTRATEGY $i $OOUTDIR/$OUT$PARAMS.$jj.ply $OFLOW";
#        }
#    if ($FLOWMODE == 3 || $FLOWMODE == 4)
#        {
        $stipplecmd="$STIPPLING $WINPUT $OOUTDIR/$OUT$PARAMS.$ii $INITIALPOINTS $INITIALPOINTSIZE $ADAPTATIVEPOINTSIZE $POINTSIZEMIN $POINTSIZEMAX $SUPERSAMPLINGFACTOR $MAXITERATIONS $HYSTERESIS $HYSTERESISDELTA $STIPPLESIZEFACTOR $FLOWMODE $HYSTERESISSTRATEGY $i $OOUTDIR/$OUT$PARAMS.$jj.ply $WPREV $WCUR $WNEXT";
#        }
    verbose($stipplecmd);
    system $stipplecmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "\nWriting  STIPPLING $ii took $hlat:$mlat:$slat \n";print RESET;
  #-----------------------------#
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
}
} #end frame loop
} #end stippling sub

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
    $CONTINUE=-1;
    $process=@line[6];
    if ($process)
      {
      print "SHOT : $SHOT\n";
      print "start/end : $FSTART $FEND\n";
      $OOUTDIR="$OUTDIR/$SHOT";
      if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
      else {$cmd="mkdir $OOUTDIR";system $cmd;}
      $CHECK="$OOUTDIR/$OUT$PARAMS";
      if (-e $CHECK && !$FORCE)
            {print BOLD RED "sequence $CHECK exists ... skipping\n";print RESET;}
      else {
        #touch file
        $touchcmd="touch $CHECK";
        if ($VERBOSE) {print "$touchcmd\n";}
        system $touchcmd;
        stippling();
        }
      }
    }
   }
else
  {
  $OOUTDIR="$OUTDIR/$SHOT";
  if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
  else {$cmd="mkdir $OOUTDIR";system $cmd;}
  $CHECK="$OOUTDIR/$OUT$PARAMS";
  if (-e $CHECK && !$FORCE)
        {print BOLD RED "sequence $CHECK exists ... skipping\n";print RESET;}
  else {
    #touch file
    $touchcmd="touch $CHECK";
    if ($VERBOSE) {print "$touchcmd\n";}
    system $touchcmd;
    stippling();
    }
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
