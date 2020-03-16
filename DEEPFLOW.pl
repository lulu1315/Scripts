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
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/opticalflow";
$OUT_USE_SHOT=0;
$OPENCV_DEEPFLOW=1;
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$DOFLOW=1;
$DOSHOWFLOW=1;
$DOSEQUENTIAL=1;
$DOREFILL=1;
$REFILLPREBLUR=3;
$REFILLGRADIENTTRESHOLD=1;
$PROCESSRESX=360;
$PRECMD="-resize2dx \$PROCESSRESX,5";
#postprocess
$FINALRESX=960;
$POSTCMD="-resize2dx \$FINALRESX,5";
#clean working dir
$CLEAN=1;
$CSV=0;
#do houdini files
$DOHOUDINI=0;
#gpu id
$GPU=0;
$GPU_OCV = "-g";
$OFFSET=1;
#showflow
$SAMPLING=20;
$VSCALE=1;
$GAMMA=.9;
$MOTIONTRESHOLD=.1;
#JSON
$CAPACITY=1000;
$SKIP="-force";
$FPT=5;
#log
$LOG1=" > /var/tmp/opticalflow.log";
$LOG2=" 2> /var/tmp/opticalflow.log";
$CSVFILE="./SHOTLIST.csv";

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
print AUTOCONF "\$FIRSTFRAME=\$FSTART\;\n";
print AUTOCONF "\$LASTFRAME=\$FEND\;\n";
print AUTOCONF confstr(OFFSET);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(OPENCV_DEEPFLOW);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(DOFLOW);
print AUTOCONF confstr(DOSHOWFLOW);
print AUTOCONF confstr(DOREFILL);
print AUTOCONF confstr(REFILLPREBLUR);
print AUTOCONF confstr(REFILLGRADIENTTRESHOLD);
print AUTOCONF confstr(DOSEQUENTIAL);
print AUTOCONF "#sizes\n";
print AUTOCONF confstr(PROCESSRESX);
print AUTOCONF "\$PRECMD=\"\-resize2dx \$PROCESSRESX,5\"\;\n";
print AUTOCONF confstr(FINALRESX);
print AUTOCONF "\$POSTCMD=\"\-resize2dx \$FINALRESX,5\"\;\n";
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(DOHOUDINI);
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(OFFSET);
print AUTOCONF confstr(CSV);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-fbornes firstframe lastframe\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
    print "-shot shotname\n";
	print "-zeropad [4]\n";
	print "-force [0]\n";
	print "-verbose\n";
	print "-gpu gpu_id [0]\n";
    print "-csv csv_file.csv\n";
    print "-json [submit to afanasy]\n";
    print "-xml  [submit to royalrender]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
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
if (@ARGV[$arg] eq "-fbornes") 
    {
    $FIRSTFRAME=@ARGV[$arg+1];
    $LASTFRAME=@ARGV[$arg+2];
    print "seq : $FIRSTFRAME $LASTFRAME\n";
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
  if (@ARGV[$arg] eq "-gpu") 
    {
    $GPU=@ARGV[$arg+1];
    print "gpu id : $GPU\n";
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
            $FIRSTFRAME=$FSTART;
            $LASTFRAME=$FEND;
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
        $FIRSTFRAME=$FSTART;
        $LASTFRAME=$FEND;
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
if ($userName eq "dev")	#
  {
  $DEEPMATCH="/shared/foss/deepmatching_1.2.2_c++/deepmatching";
  $DEEPFLOW2="/shared/foss/deep-flow/deep_flow2/deepflow2";
  $DEEPFLOW_OPENCV="/shared/foss/FlowCode/build/deepflow_opencv";
  $FLO2EXR="/shared/foss/FlowCode/build/flo2exr";
  $EXR2FLO="/shared/foss/FlowCode/build/exr2flo";
  $CONSISTENCYCHECK="/shared/foss/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/shared/foss/gmic/src/gmic";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  }
  
if ($userName eq "dev18" || $userName eq "render")	#
  {
  $GMIC="/shared/foss-18/gmic-2.8.3_pre/build/gmic";
  $DEEPMATCH="/shared/foss-18/DeepFlow/deepmatching";
  $DEEPFLOW2="/shared/foss-18/DeepFlow/deepflow2";
  $DEEPFLOW_OPENCV="/shared/foss-18/FlowCode/build/deepflow_opencv";
  $FLO2EXR="/shared/foss/FlowCode/build/flo2exr";
  $EXR2FLO="/shared/foss/FlowCode/build/exr2flo";
  $CONSISTENCYCHECK="/shared/foss-18/artistic-videos//consistencyChecker/consistencyChecker";
  $SHOWFLOW="/shared/foss-18/FlowCode/build/showflow";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  }
  
if ($userName eq "lulu") # Nanterre
  {
  $DEEPMATCH="/mnt/shared/v16/deepmatching_1.2.2_c++/deepmatching";
  $DEEPFLOW2="/mnt/shared/v16/deep-flow/deep_flow2/deepflow2";
  $FLO2EXR="/mnt/shared/v16/bin/flo2exr";
  $EXR2FLO="/mnt/shared/v16/bin/exr2flo";
  $CONSISTENCYCHECK="/mnt/shared/v16/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/usr/bin/gmic";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  }

sub opticalflow {
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
    $FIRSTFRAME=$min;
    $LASTFRAME=$max;
    print ("final seq    : $FSTART $FEND\n");
    print ("seq boundary : $FIRSTFRAME $LASTFRAME\n");
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
    $FIRSTFRAME=$CSVFSTART;
    $LASTFRAME=$CSVFEND;
    print ("final seq : $FSTART $FEND\n");
    print ("seq boundary : $FIRSTFRAME $LASTFRAME\n");
    }
    
if ($OUT_USE_SHOT) {$OOUTDIR="$OUTDIR/$SHOT";}
else {$OOUTDIR="$OUTDIR";}
    
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
if (-e "$OOUTDIR/dual") {print "$OOUTDIR/dual already exists\n";}
    else {$cmd="mkdir $OOUTDIR/dual";system $cmd;}
if (-e "$OOUTDIR/sequential") {print "$OOUTDIR/sequential already exists\n";}
    else {$cmd="mkdir $OOUTDIR/sequential";system $cmd;}
if (-e "$OOUTDIR/showflow") {print "$OOUTDIR/showflow already exists\n";}
    else {$cmd="mkdir $OOUTDIR/showflow";system $cmd;}
if (-e "$OOUTDIR/refill") {print "$OOUTDIR/refill already exists\n";}
    else {$cmd="mkdir $OOUTDIR/refill";system $cmd;}
    
for ($i = $FSTART ;$i <= $FEND ;$i++)
{
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#
if ($i == $LASTFRAME) {$j=$i;} else {$j=$i+$OFFSET;} #cheat pour renderfarm
#$k=$i-$OFFSET;

if ($ZEROPAD == 4)
    {
    $ii=sprintf("%04d",$i);
    $jj=sprintf("%04d",$j);
    }
if ($ZEROPAD == 5)
    {
    $ii=sprintf("%05d",$i);
    $jj=sprintf("%05d",$j);
    }

if ($IN_USE_SHOT)
    {
    $FILE1="$INDIR/$SHOT/$IN.$ii.$EXT";
    $FILE2="$INDIR/$SHOT/$IN.$jj.$EXT";
    }
else
    {
    $FILE1="$INDIR/$IN.$ii.$EXT";
    $FILE2="$INDIR/$IN.$jj.$EXT";
    }

#dual
$FORWARD        ="$OOUTDIR/dual/forward_$ii\_$jj.flo";
$BACKWARD       ="$OOUTDIR/dual/backward_$jj\_$ii.flo";
$EXRFORWARD     ="$OOUTDIR/dual/forward_$ii\_$jj.exr";
$EXRBACKWARD    ="$OOUTDIR/dual/backward_$jj\_$ii.exr";
#sequential
$NEXT           ="$OOUTDIR/sequential/next.$ii.flo";
$PREV           ="$OOUTDIR/sequential/prev.$jj.flo";
$EXRNEXT        ="$OOUTDIR/sequential/next.$ii.exr";
$EXRPREV        ="$OOUTDIR/sequential/prev.$jj.exr";
#refill
$REFILLMASK="$OOUTDIR/refill/refillmask.$ii.png";
$FLOBACKWARDREFILL="$OOUTDIR/refill/backward_$jj\_$ii.flo";
$FLOFORWARDREFILL="$OOUTDIR/refill/forward_$ii\_$jj.flo";
$EXRPREVREFILL="$OOUTDIR/sequential/prev_refill.$jj.exr";
$EXRNEXTREFILL="$OOUTDIR/sequential/next_refill.$ii.exr";
#preprocess
$WORKDIR="$OOUTDIR/w$ii";
$WFILE1="$WORKDIR/$IN.$ii.$EXT";
$WFILE2="$WORKDIR/$IN.$jj.$EXT";
#workdir files
$WFORWARD       ="$WORKDIR/forward.flo";
$WBACKWARD      ="$WORKDIR/backward.flo";
$WFORWARDEXR    ="$WORKDIR/forward.exr";
$WBACKWARDEXR   ="$WORKDIR/backward.exr";
#showflow
$SHOWFORWARD="$OOUTDIR/dual/forward_$ii\_$jj";
$OUTSHOWFORWARD="$OOUTDIR/showflow/forward.$ii.jpg";
$SHOWBACKWARD="$OOUTDIR/dual/backward_$jj\_$ii";
$OUTSHOWBACKWARD="$OOUTDIR/showflow/backward.$jj.jpg";

#flo files
if ($DOFLOW)
    {
    if (-e $FORWARD && !$FORCE)
        {print BOLD RED "opticalflow : frame $ii exists ... skipping\n";print RESET;}
    else
        {
        #touch
        $touchcmd="touch $FORWARD";
        system $touchcmd;
        #
        $framesleft=($FEND-$i);
        print BOLD YELLOW ("\nprocessing frame $ii ($FSTART-$FEND) $framesleft frames to go .. [shot: $SHOT]\n");print RESET;
        #preprocess
        verbose("preprocessing frame $ii");
        if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        $gmiccmd="$GMIC -i $FILE1 $PRECMD -o $WFILE1 $LOG2";
        verbose($gmiccmd);
        print("--------> processing $IN.$ii.$EXT [$PRECMD]\n");
        system $gmiccmd;
        $gmiccmd="$GMIC -i $FILE2 $PRECMD -o $WFILE2 $LOG2";
        verbose($gmiccmd);
        print("--------> processing $IN.$jj.$EXT [$PRECMD]\n");
        system $gmiccmd;
        #flow
        if ($OPENCV_DEEPFLOW)
            {
            $cmd1="$DEEPFLOW_OPENCV $GPU_OCV $WFILE1 $WFILE2 $WFORWARD";
            $cmd2="$DEEPFLOW_OPENCV $GPU_OCV $WFILE2 $WFILE1 $WBACKWARD";
            }
        else
            {
            $cmd1="$DEEPMATCH $WFILE1 $WFILE2 -nt 0 | $DEEPFLOW2 $WFILE1 $WFILE2 $WFORWARD -match -sintel $LOG1";
            $cmd2="$DEEPMATCH $WFILE2 $WFILE1 -nt 0 | $DEEPFLOW2 $WFILE2 $WFILE1 $WBACKWARD -match -sintel $LOG1";
            }
        verbose($cmd1);
        print("--------> opticalflow forward  [$ii->$jj] opencv : [$OPENCV_DEEPFLOW]\n");
        system $cmd1;
        verbose($cmd2);
        print("--------> opticalflow backward [$jj->$ii] opencv : [$OPENCV_DEEPFLOW]\n");
        system $cmd2;
        
        #resize
        if ($FINALRESX != $PROCESSRESX)
            {
            $MOTIONRATIO=$FINALRESX/$PROCESSRESX;
            #forward convert flo to exr
            $cmd="$FLO2EXR $WFORWARD $WFORWARDEXR $LOG1";
            verbose($cmd);
            print("--------> flo2exr forward [resizing]\n");
            system $cmd;
            #resize exr to finalres
            $cmd="$GMIC -i $WFORWARDEXR $POSTCMD -mul $MOTIONRATIO -o $WFORWARDEXR $LOG2";
            verbose($cmd);
            print("--------> resizing [$POSTCMD motionratio:$MOTIONRATIO]\n");
            system $cmd;
            #reconvert resized to flo
            $cmd="$EXR2FLO $WFORWARDEXR $FORWARD $LOG1";
            verbose($cmd);
            print("--------> exr2flo forward [resizing]\n");
            system $cmd;
            #backward convert flo to exr
            $cmd="$FLO2EXR $WBACKWARD $WBACKWARDEXR $LOG1";
            verbose($cmd);
            print("--------> flo2exr backward [resizing]\n");
            system $cmd;
            #resize exr to finalres
            $cmd="$GMIC -i $WBACKWARDEXR $POSTCMD -mul $MOTIONRATIO -o $WBACKWARDEXR $LOG2";
            verbose($cmd);
            print("--------> resizing [$POSTCMD motionratio:$MOTIONRATIO]\n");
            system $cmd;
            #reconvert resized to flo
            $cmd="$EXR2FLO $WBACKWARDEXR $BACKWARD $LOG1";
            verbose($cmd);
            print("--------> exr2flo backward [resizing]\n");
            system $cmd;
            }
    #consistency
    $consistencycmd="$CONSISTENCYCHECK $BACKWARD $FORWARD $OOUTDIR/dual/reliable_$jj\_$ii.pgm $LOG1";
    verbose($consistencycmd);
    print("--------> consistency backward [$jj->$ii]\n");
    system $consistencycmd;
    $consistencycmd="$CONSISTENCYCHECK $FORWARD $BACKWARD $OOUTDIR/dual/reliable_$ii\_$jj.pgm $LOG1";
    verbose($consistencycmd);
    print("--------> consistency forward  [$ii->$jj] \n");
    system $consistencycmd;
        
    #showflow
    if ($DOSHOWFLOW) 
        {
        $cmd="$SHOWFLOW $SHOWFORWARD flo $FILE1 255 $OUTSHOWFORWARD $SAMPLING $VSCALE $GAMMA $MOTIONTRESHOLD $LOG1";
        verbose($cmd);
        print("--------> showflow forward\n");
        system $cmd;
        $cmd="$SHOWFLOW $SHOWBACKWARD flo $FILE2 255 $OUTSHOWBACKWARD $SAMPLING $VSCALE $GAMMA $MOTIONTRESHOLD $LOG1";
        verbose($cmd);
        print("--------> showflow backward\n");
        system $cmd;
        }
    }
}#end doflow

if ($DOREFILL)
    {
    if (-e $REFILLMASK && !$FORCE)
        {print BOLD RED "refill : frame $ii exists ... skipping\n";print RESET;}
    else
        {
        #all in one
        #$cmd="$GMIC $FILE1 -b $REFILLPREBLUR -luminance -gradient_norm -le $REFILLGRADIENTTRESHOLD $EXRBACKWARD -inpaint_flow[1] [0] -o[1] $EXRBACKWARDREFILL $LOG2";
        #print("--------> refill dual prev $jj->$ii\n");
        #inpaint flow
        #$cmd="$GMIC $REFILLMASK div 255 $EXRBACKWARD -inpaint_flow[1] [0] -o[1] $EXRBACKWARDREFILL $LOG2";
        #inpaint pde
        #diffusion_type={ 0=isotropic | 1=delaunay-guided | 2=edge-guided }
        $DIFFUSIONTYPE=0;
        #compute mask
        $cmd="$GMIC $FILE1 -b $REFILLPREBLUR -luminance -gradient_norm -le $REFILLGRADIENTTRESHOLD mul 255 -resize2dx $FINALRESX,5 -c 0,255 -o $REFILLMASK $LOG2";
        verbose($cmd);
        print("--------> compute gradient mask $ii\n");
        system $cmd;
        #refill backward
        $cmd="$GMIC $REFILLMASK div 255 $BACKWARD -inpaint_pde[1] [0],75%,$DIFFUSIONTYPE,20 -o[1] $FLOBACKWARDREFILL $LOG2";
        verbose($cmd);
        print("--------> refill backward flow $jj->$ii\n");
        system $cmd;
        #refill forward
        $cmd="$GMIC $REFILLMASK div 255 $FORWARD -inpaint_pde[1] [0],75%,$DIFFUSIONTYPE,20 -o[1] $FLOFORWARDREFILL $LOG2";
        verbose($cmd);
        print("--------> refill forward flow $ii->$jj\n");
        system $cmd;
        
        #showflow
        if ($DOSHOWFLOW) 
            {
            $SHOWFORWARD="$OOUTDIR/refill/forward_$ii\_$jj";
            $OUTSHOWFORWARD="$OOUTDIR/showflow/refillforward.$ii.jpg";
            $SHOWBACKWARD="$OOUTDIR/refill/backward_$jj\_$ii";
            $OUTSHOWBACKWARD="$OOUTDIR/showflow/refillbackward.$jj.jpg";
            $cmd="$SHOWFLOW $SHOWFORWARD flo $FILE1 255 $OUTSHOWFORWARD $SAMPLING $VSCALE $GAMMA $MOTIONTRESHOLD $LOG1";
            verbose($cmd);
            print("--------> refill showflow forward\n");
            system $cmd;
            $cmd="$SHOWFLOW $SHOWBACKWARD flo $FILE2 255 $OUTSHOWBACKWARD $SAMPLING $VSCALE $GAMMA $MOTIONTRESHOLD $LOG1";
            verbose($cmd);
            print("--------> refill showflow backward\n");
            system $cmd;
            }
        }
    }
    
if ($DOSEQUENTIAL)
    {
    if (-e $EXRNEXT && !$FORCE)
        {print BOLD RED "sequential : frame $ii exists ... skipping\n";print RESET;}
    else
        {
        #forward -> next
        $cmd="$FLO2EXR $FORWARD $EXRNEXT $LOG2";
        verbose($cmd);
        print(" [+forward sequential]\n");
        system $cmd;
        $cmd="$GMIC $OOUTDIR/dual/reliable_$ii\_$jj.pgm -o $OOUTDIR/sequential/reliablenext.$ii.png $LOG2";
        verbose($cmd);
        print(" [+consistency forward sequential]\n");
        system $cmd;
    #if ($i == $LASTFRAME)
    #    {
    #    $cmd="$GMIC -i $FORWARD -mul[0] 0 -o $EXRNEXT $LOG2";
    #    verbose($cmd);
    #    print("--------> sequential/next.$ii.exr is a black frame\n");
    #    system $cmd;
    #    $cmd="$GMIC -i $OOUTDIR/dual/reliable_$ii\_$jj.pgm -mul 0 -o $OOUTDIR/sequential/reliablenext.$ii.png $LOG2";
    #    verbose($cmd);
    #    print("--------> sequential/reliablenext.$ii.pgm is a black frame\n");
    #    system $cmd;
    #    }
    #backward -> prev
        $cmd="$FLO2EXR $BACKWARD $EXRPREV $LOG2";
        verbose($cmd);
        print(" [+backward sequential]\n");
        system $cmd;
        $cmd="$GMIC $OOUTDIR/dual/reliable_$jj\_$ii.pgm -o $OOUTDIR/sequential/reliableprev.$jj.png $LOG2";
        verbose($cmd);
        print(" [+consistency backward sequential]\n");
        system $cmd;
    #if ($i == $FIRSTFRAME)
    #    {
    #    $cmd="$GMIC -i $BACKWARD -mul[0] 0 -o $EXRPREV $LOG2";
    #    verbose($cmd);
    #    print("--------> sequential/prev.$ii.exr is a black frame\n");
    #    system $cmd;
    #    $cmd="$GMIC -i $OOUTDIR/dual/reliable_$jj\_$ii.pgm -mul 0 -o $OOUTDIR/sequential/reliableprev.$ii.png $LOG2";
    #    verbose($cmd);
    #    print("--------> sequential/reliableprev.$ii.pgm is a black frame\n");
    #    system $cmd;
    #    }
        if ($DOREFILL) {
            $cmd="$FLO2EXR $FLOBACKWARDREFILL $EXRPREVREFILL $LOG1";
            verbose($cmd);
            print(" [+refill backward sequential]\n");
            system $cmd;
            $cmd="$FLO2EXR $FLOFORWARDREFILL $EXRNEXTREFILL $LOG1";
            verbose($cmd);
            print(" [+refill forward sequential]\n");
            system $cmd;
        }
    }
} #end sequential

    if ($CLEAN && -d $WORKDIR)
        {
        $cleancmd="rm -r $WORKDIR";
        verbose($cleancmd);
        system $cleancmd;
        }
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    print BOLD YELLOW "Writing next.$ii.exr opticalflow all frames took $hlat:$mlat:$slat \n";
    print RESET;
}

if ($DOHOUDINI)
{
#do houdini scene
print BOLD GREEN "generating houdini files\n";print RESET;
#get resolutions
$colorima = Image::Magick->new;
$colorima->Read($FILE1);
$colorresx = $colorima->[0]->Get('width');
$colorresy = $colorima->[0]->Get('height');
$motionima = Image::Magick->new;
$motionima->Read($EXRNEXT);
$motionresx = $motionima->[0]->Get('width');
$motionresy = $motionima->[0]->Get('height');
#copy houdini template
$HOUDIR="$OUTDIR/houdini";
if (-e "$HOUDIR") {print "$HOUDIR already exists\n";}
    else {$cmd="mkdir $HOUDIR";system $cmd;}
$cmd="cp /shared1/Scripts/hipref/visualize_motionvectors.hip $HOUDIR/visualize_motionvectors.hip";
print "$cmd \n";
system $cmd;

#create hscript cmd
$hscriptfile = "$HOUDIR/hscript.cmd";
open (HSCRIPT , "> $hscriptfile");
print HSCRIPT "mread $HOUDIR/visualize_motionvectors.hip\n";
print HSCRIPT "opparm /obj/screen/CONTROLS framestart $FIRSTFRAME\n";
print HSCRIPT "opparm /obj/screen/CONTROLS frameend $LASTFRAME\n";
print HSCRIPT "opparm /obj/screen/CONTROLS ProjectName $PROJECT\n";
print HSCRIPT "opparm /obj/screen/CONTROLS mycolor originales/$IN\n";
print HSCRIPT "opparm /obj/screen/CONTROLS motionnext opticalflow/next\n";
print HSCRIPT "opparm /obj/screen/CONTROLS motionprev opticalflow/prev\n";
print HSCRIPT "opparm /obj/screen/CONTROLS colorresx $colorresx\n";
print HSCRIPT "opparm /obj/screen/CONTROLS colorresy $colorresy\n";
print HSCRIPT "opparm /obj/screen/CONTROLS motionresx $motionresx\n";
print HSCRIPT "opparm /obj/screen/CONTROLS motionresy $motionresy\n";
print HSCRIPT "mwrite $HOUDIR/visualize_motionvectors.hip\n";
print HSCRIPT "q\n";
close HSCRIPT;
$hcmd = "$HSCRIPT $hscriptfile";
print "$hcmd\n";
system $hcmd;
}
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

sub json {
$CMD="OPTICALFLOW";
$FRAMESINC=1;
$PARSER="perl";
$SERVICE="perl";
$OFFLINE="true";

$WORKINGDIR=$CWD;
$BLOCKNAME="$scriptname\_$SHOT";
$JOBNAME="$scriptname\_$PROJECT\_$SHOT";
    
if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT -fbornes $FIRSTFRAME $LASTFRAME";
    $FILES="$OUTDIR/$SHOT/sequential/next.\@####\@.exr";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -fbornes $FIRSTFRAME $LASTFRAME";
    $FILES="$OUTDIR/sequential/next.\@####\@.exr";
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
$LAYER="$PROJECT\_next_$SHOT";
if ($OUT_USE_SHOT)
    {
    $OUTPUT="$SHOT/sequential/next.";
    }
else
    {
    $OUTPUT="sequential/next.";
    }
    
print "xml layer  : $LAYER\n";
print "xml outdir : $OUTDIR\n";
print "xml outname: $OUTPUT\n";

print XML "<Job>\n";
print XML "  <IsActive> true </IsActive>\n";
print XML "  <SceneName>   $SCENENAME/$CONF      </SceneName>\n";
print XML "  <SceneDatabaseDir>  $SCENENAME   </SceneDatabaseDir>\n";
print XML "  <Software>     opticalflow     </Software>\n";
print XML "  <SeqStart>     $FSTART     </SeqStart>\n";
print XML "  <SeqEnd>      $FEND     </SeqEnd>\n";
print XML "  <Layer>    $LAYER      </Layer>\n";
print XML "  <ImageDir>   $OUTDIR/    </ImageDir>\n";
print XML "  <ImageFilename>     $OUTPUT     </ImageFilename>\n";
print XML "  <ImageExtension>     .exr    </ImageExtension>\n";
print XML "  <ImageFramePadding>     4     </ImageFramePadding>\n";
print XML "  <CustomA>   -shot $SHOT -fbornes $FIRSTFRAME $LASTFRAME  </CustomA>\n";
print XML "</Job>\n";
}
