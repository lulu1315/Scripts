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
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/coherent";
$DOETF=1;
$DOFLOW=1;
$GRADIENTOUT="gradient";
$TANGENTOUT="tangent";
$CLDOUT="coherent";
$OUT_USE_SHOT=0;
$EXT="png";
#$EXTIN="\$EXT";
$EXTOUT="exr";
#preprocess
$DOLOCALCONTRAST=0;
$EQUALIZE=0;
$EQUALIZEMIN="20%";
$EQUALIZEMAX="80%";
$ROLLING=0;
$INBLUR=0;
$DOBILATERAL=0;
$BILATERALSPATIAL=5;
$BILATERALVALUE=5;
$BILATERALITER=1;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$SIZE=0;
#
$ETFKERNELSIZE=15;
$ETFITERATIONS=1;
#Coherent Line Drawing
$CLDFDOGITERATION=1;
$CLDSIGMAM=2;
$CLDSIGMAC=1;
$CLDRHO=.995;
$CLDTAU=.99;
#post process
$DILATE=0;
$EDGESMOOTH=0;
$DOPOTRACE=1;
$BLACKLEVEL=.5;
$DODESPECKLE=0;
$DESPECKLEMAXAREA=5;
$DESPECKLETOLERANCE=30;
$INVFINAL=0;
#
$ZEROPAD=4;
$FORCE=0;
$VERBOSE=0;
$CSV=0;
$CLEAN=1;
$LOG1=">/var/tmp/coherent.log";
$LOG2="2>/var/tmp/coherent.log";
$PARAMS="";
$CSVFILE="./SHOTLIST.csv";
#JSON
$CAPACITY=500;
$SKIP="-force";
$FPT=2;

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
open (AUTOCONF,">","coherent_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(DOETF);
print AUTOCONF confstr(DOFLOW);
print AUTOCONF confstr(GRADIENTOUT);
print AUTOCONF confstr(TANGENTOUT);
print AUTOCONF confstr(CLDOUT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF confstr(EQUALIZEMIN);
print AUTOCONF confstr(EQUALIZEMAX);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(INBLUR);
print AUTOCONF confstr(DOBILATERAL);
print AUTOCONF confstr(BILATERALSPATIAL);
print AUTOCONF confstr(BILATERALVALUE);
print AUTOCONF confstr(BILATERALITER);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(SIZE);
print AUTOCONF "#Edge Tangent Flow (ETF);\n";
print AUTOCONF confstr(ETFKERNELSIZE);
print AUTOCONF confstr(ETFITERATIONS);
print AUTOCONF "#Coherent Line Drawing (CLD)\n";
print AUTOCONF confstr(CLDFDOGITERATION);
print AUTOCONF confstr(CLDSIGMAM);
print AUTOCONF confstr(CLDSIGMAC);
print AUTOCONF confstr(CLDRHO);
print AUTOCONF confstr(CLDTAU);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(DOPOTRACE);
print AUTOCONF confstr(BLACKLEVEL);
print AUTOCONF confstr(DODESPECKLE);
print AUTOCONF confstr(DESPECKLEMAXAREA);
print AUTOCONF confstr(DESPECKLETOLERANCE);
print AUTOCONF confstr(INVFINAL);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(PARAMS);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
print AUTOCONF "1";
}

sub gradientrefillconf {
print AUTOCONF "\$INBLUR=10\;\n";
print AUTOCONF "\$OUTBLUR=2\;\n";
print AUTOCONF "\$REFILL=.1\;\n";
print AUTOCONF "\$EXTIN=\"$EXTIN\"\;\n";
print AUTOCONF "\$EXTOUT=\"exr\"\;\n";
print AUTOCONF "\$OP=\"-blur \$INBLUR -luminance -gradient 100%,100%,1,1 -a[0,1,2] c --norm -le[1] \$REFILL -inpaint[0] [1],0 -b[0] \$OUTBLUR -rm[1]\"\;\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-step step[1]\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-shot shotname\n";
	print "-force [0]\n";
	print "-verbose\n";
    print "-csv csv_file.csv\n";
    print "-json [submit to afanasy]\n";
    print "-xml  [submit to royalrender]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing coherent_auto.conf : mv coherent_auto.conf coherent.conf\n";
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
    print "verbose on\n";
    }
  if (@ARGV[$arg] eq "-cld") 
    {
    $CLDFDOGITERATION=@ARGV[$arg+1];
    $CLDSIGMAM=@ARGV[$arg+2];
    $CLDSIGMAC=@ARGV[$arg+3];
    $CLDRHO=@ARGV[$arg+4];
    print BOLD BLUE "cld [iter:$CLDFDOGITERATION sigmam:$CLDSIGMAM sigmac:$CLDSIGMAC rho:$CLDRHO]\n";print RESET;
    }
  if (@ARGV[$arg] eq "-etf") 
    {
    $ETFKERNELSIZE=@ARGV[$arg+1];
    $ETFITERATIONS=@ARGV[$arg+2];
    print BOLD BLUE "etf [kernel size:$ETFKERNELSIZE iterations:$ETFITERATIONS\n";print RESET;
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    }
  if (@ARGV[$arg] eq "-json") 
    {
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
                json();
                }
            }
        }
        else
        {
        json();
        }
    exit;
    }
  if (@ARGV[$arg] eq "-xml") 
    {
    open (XML,">","submit.xml");
    print XML "<rrJob_submitFile syntax_version=\"6.0\">\n";
    print XML "<DeleteXML>1</DeleteXML>\n";
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
            xml();
            }
        }
    }
    else
    {
    xml();
    }
    print XML "</rrJob_submitFile>\n";
    $cmd="/shared/apps/royal-render/lx__rrSubmitter.sh submit.xml";
    print $cmd;
    system $cmd;
    exit;
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "lulu" || $userName eq "dev")	#
  {
  #$GMIC="/usr/bin/gmic";
  $GMIC="/shared/foss/gmic/src/gmic";
  $POTRACE="/usr/bin/potrace";
  #$EXR2FLO="/shared/Scripts/bin/exr2flo";
  $EXR2FLO="/shared/foss/FlowCode/build/exr2flo";
  $ETF="/shared/foss/Coherent-Line-Drawing/build/ETF-cli";
  $CLD="/shared/foss/Coherent-Line-Drawing/build/CLD-cli";
  $CLDOFLOW="/shared/foss/Coherent-Line-Drawing/build/CLD-oflow-cli";
  }
  
if ($userName eq "dev18"  || $userName eq "render")	#
  {
  $GMIC="/shared/foss-18/gmic-2.8.3_pre/build/gmic";
  $POTRACE="/usr/bin/potrace";
  $EXR2FLO="/shared/foss-18/FlowCode/build/exr2flo";
  $ETF="/shared/foss-18/Coherent-Line-Drawing/build/ETF-cli";
  $CLD="/shared/foss-18/Coherent-Line-Drawing/build/CLD-cli";
  $CLDOFLOW="/shared/foss-18/Coherent-Line-Drawing/build/CLD-oflow-cli";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}
if ($INVFINAL) 
    {$GMICINV = "-n 0,1 -oneminus -n 0,255";} else {$GMICINV = "";}
    
sub csv {

#$PARAMS="_k$ETFKERNELSIZE\_i$ETFITERATIONS\_i$CLDFDOGITERATION\_sm$CLDSIGMAM\_sc$CLDSIGMAC\_rho$CLDRHO";

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
    
for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
{

if ($ZEROPAD == 4)
    {
    $ii=sprintf("%04d",$i);
    }
if ($ZEROPAD == 5)
    {
    $ii=sprintf("%05d",$i);
    }

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
    $GOUT="$OOUTDIR/$GRADIENTOUT$PARAMS.$ii.$EXTOUT";
    $GFLOUT="$OOUTDIR/$GRADIENTOUT$PARAMS.$ii.flo";
    $TOUT="$OOUTDIR/$TANGENTOUT$PARAMS.$ii.$EXTOUT";
    $TFLOUT="$OOUTDIR/$TANGENTOUT$PARAMS.$ii.flo";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $WORKDIR="$OOUTDIR/w$$";
    $OOUT="$OOUTDIR/$CLDOUT$PARAMS.$ii.$EXT";
    }
else
    {
    $GOUT="$OUTDIR/$GRADIENTOUT$PARAMS.$ii.$EXTOUT";
    $GFLOUT="$OUTDIR/$GRADIENTOUT$PARAMS.$ii.flo";
    $TOUT="$OUTDIR/$TANGENTOUT$PARAMS.$ii.$EXTOUT";
    $TFLOUT="$OUTDIR/$TANGENTOUT$PARAMS.$ii.flo";
    $WORKDIR="$OUTDIR/w$$";
    $OOUT="$OUTDIR/$CLDOUT$PARAMS.$ii.$EXT";
    }
    

if (-e $OOUT && !$FORCE)
   {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #
  $framesleft=($FEND-$i);
  print BOLD YELLOW ("\nprocessing frame $ii ($FSTART-$FEND) $framesleft frames to go ..\n");print RESET;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #preprocess
  $I=1;
  if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} 
    else {$GMIC1="";}
  if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} 
  if ($EQUALIZE) 
        {$GMIC5="-equalize 256,$EQUALIZEMIN,$EQUALIZEMAX";} 
    else {$GMIC5="";}
  if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
    else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} 
  if ($INBLUR) 
        {$GMIC6="-blur $INBLUR";} 
    else {$GMIC6="";}
  if ($DOBILATERAL) 
        {$GMIC7="-fx_smooth_bilateral $BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER,0,0";} 
    else {$GMIC7="";}
  $cmd="$GMIC -i $IIN $GMIC5 $GMIC4 $GMIC1 $GMIC2 $GMIC3 $GMIC6 $GMIC7 -o $WORKDIR/$I.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE equalize:$EQUALIZE lce:$DOLOCALCONTRAST rolling:$ROLLING blur:$INBLUR bilateral:$DOBILATERAL,$BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  $tmpcmd="cp $IIN $WORKDIR/0.png";
  system $tmpcmd;
  $IIN="$WORKDIR/$I.png";
  #Coherent edge flow
  if ($DOETF)
    {
    $cmd="$ETF $IIN $ETFKERNELSIZE $ETFITERATIONS $GOUT $TOUT";
    verbose($cmd);
    print("--------> Edge Tangent Flow [kernel:$ETFKERNELSIZE iterations:$ETFITERATIONS]\n");
    system $cmd;
    }
  if ($DOFLOW)
    {
    $gflocmd="$EXR2FLO $GOUT $GFLOUT";
    $tflocmd="$EXR2FLO $TOUT $TFLOUT";
    verbose($gflocmd);
    print("--------> convert gradient to flo format\n");
    system $gflocmd;
    verbose($tflocmd);
    print("--------> convert tangent to flo format\n");
    system $tflocmd;
    }
  #cld
  $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
  $cmd="$GMIC $PIN -to_colormode 1 -o $POUT $LOG2";
  verbose($cmd);
  system $cmd;
  $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.pgm";
  $cmd="$CLD $PIN $TOUT $CLDFDOGITERATION $CLDSIGMAM $CLDSIGMAC $CLDRHO $CLDTAU $POUT";
  verbose($cmd);
  print("--------> Coherent Line Drawing [DogF iter:$CLDFDOGITERATION sigma_m:$CLDSIGMAM sigma_c:$CLDSIGMAC rho:$CLDRHO tau:$CLDTAU]\n");
  system $cmd;
  if ($DILATE)
    {
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GMIC $PIN -dilate_circ $DILATE -b 1 -o $POUT $LOG2";
    verbose($cmd);
    print("--------> dilate_circ [dilate:$DILATE]\n");
    system $cmd;
    }
  if ($DOPOTRACE)
    {
    #convert to pgm
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GMIC -i $PIN -o $POUT $LOG2";
    verbose($cmd);
    print("--------> gmic : convert to pgm for potrace\n");
    system $cmd;
    #potrace
    $PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$POTRACE $PIN -o $POUT -g -k $BLACKLEVEL";
    verbose($cmd);
    print("--------> potrace [blacklevel:$BLACKLEVEL]\n");
    system $cmd;
    #bug potrace
    $cmd="convert $POUT $OOUT";
    verbose($cmd);
    print("--------> potrace bug\n");
    system $cmd;
    }
  else
    {
    #--> output
    $cmd="$GMIC -i $POUT -to_colormode 3 -o $OOUT $LOG2";
    verbose($cmd);
    system $cmd;
    }
  if ($EDGESMOOTH) 
    {
    #$PIN="$WORKDIR/$I.pgm";$I++;$POUT="$WORKDIR/$I.pgm";
    $cmd="$GMIC $OOUT -fx_dreamsmooth 10,0,1,1,0,0.8,0,24,0 -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> dreamsmooth\n");
    system $cmd;
    }
  if ($DODESPECKLE) 
    {
    $cmd="$GMIC $OOUT gcd_despeckle $DESPECKLETOLERANCE,$DESPECKLEMAXAREA -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> despeckle [tolerance:$DESPECKLETOLERANCE max area:$DESPECKLEMAXAREA\n");
    system $cmd;
    }
  if ($INVFINAL)
    {
    $cmd="$GMIC $OOUT $GMICINV -o $OOUT $LOG2";
    verbose($cmd);
    print("--------> inverting final\n");
    system $cmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #-----------------------------#
  #afanasy parsing format
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
  #print "\n";
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  }
}
}

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
  
#gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    return $key1+$keycount*(($key2-$key1)/($KEYFRAME-1));
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

sub json {
$CMD="COHERENT";
$FRAMESINC=1;
$PARSER="perl";
$SERVICE="perl";
$OFFLINE="true";

$WORKINGDIR=$CWD;
$BLOCKNAME="$OUT\_$SHOT";
$JOBNAME="$scriptname\_$OUT\_$SHOT";
    
if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT";
    $FILES="$OUTDIR/$SHOT/$CLDOUT$PARAMS.\@####\@.$EXT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP";
    $FILES="$OUTDIR/$CLDOUT$PARAMS.\@####\@.$EXT";
    }
$HOSTNAME = `hostname -s`;
chop $HOSTNAME;
$USERNAME =  $ENV{'USER'}; 

$JSON="{\"job\":{\"blocks\":[{\"command\":\"$COMMAND\",\"files\":[\"$FILES\"],\"flags\":1,\"frame_first\":$FSTART,\"frame_last\":$FEND,\"frames_inc\":1,\"frames_per_task\":$FPT,\"name\":\"$BLOCKNAME\",\"parser\":\"$PARSER\",\"service\":\"$SERVICE\",\"capacity\":$CAPACITY,\"working_directory\":\"$WORKINGDIR\"}],\"host_name\":\"$HOSTNAME\",\"name\":\"$JOBNAME\",\"offline\":$OFFLINE,\"user_name\":\"$USERNAME\"}}";

print "$JSON\n";;
$JSONFILE="./cgru.json";
open( JSON , '>', $JSONFILE);
print JSON $JSON;
close JSON;

$sendcmd="afcmd json send $JSONFILE";
print "$sendcmd\n";
system $sendcmd;
$clean="rm $JSONFILE";
print "$clean\n";
system $clean;
}

sub xml {
$SCENENAME=getcwd;
$LAYER="$PROJECT\_$OUT\_$SHOT";
if ($OUT_USE_SHOT)
    {
    $OUTPUT="$SHOT/$OUT.";
    }
else
    {
    $OUTPUT="$OUT.";
    }

print XML "<Job>\n";
print XML "  <IsActive> true </IsActive>\n";
print XML "  <SceneName>   $SCENENAME/$CONF      </SceneName>\n";
print XML "  <SceneDatabaseDir>  $SCENENAME   </SceneDatabaseDir>\n";
print XML "  <Software>     gmic     </Software>\n";
print XML "  <SeqStart>     $FSTART     </SeqStart>\n";
print XML "  <SeqEnd>      $FEND     </SeqEnd>\n";
print XML "  <Layer>    $LAYER      </Layer>\n";
print XML "  <ImageDir>   $OUTDIR/    </ImageDir>\n";
print XML "  <ImageFilename>     $OUTPUT     </ImageFilename>\n";
print XML "  <ImageExtension>     .$EXTOUT     </ImageExtension>\n";
print XML "  <ImageFramePadding>     4     </ImageFramePadding>\n";
print XML "  <CustomA>     $SHOT     </CustomA>\n";
print XML "</Job>\n";
}
