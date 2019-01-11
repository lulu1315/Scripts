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
$METHOD="0";
$OPENCV_DEEPFLOW=0;
#0 -> deepflow2 : works everywhere
#1 -> flownet2  : GPU needed (s00X,v80X)
#2 -> OFDIS     : problem on AMD (SSE?)
#3 -> EPPM      : GPU needed
#4 -> RIC       : 
#5 -> PWC-Net   : pytorch
#6 -> Unflow    : pytorch
#7 -> Spynet    : pytorch
$PWCMODEL="default";
$SPYMODEL="sintel-final";
$FSTART="auto";
$FEND="auto";
#debut ou fin de sequence
$FIRSTFRAME=$FSTART;
$LASTFRAME=$FEND;
#
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/opticalflow";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$DOFLOW=1;
$DORELIABLE=1;
$DOCOLORFLOW=0;
$NORMALISATION=20;
$DOEXR=1;
$DOSEQUENTIAL=1;
$DOREFILL=0;
$REFILLMETHOD=1;
#0=low-connectivity average
#1=high-connectivity average
#2=low-connectivity median
#3=high-connectivity median
#preprocess
#size pour EPPM
$SIZEX=128;
$SIZEY=96;
$PROCESSRESX=360;
$PRECMD="-resize2dx \$PROCESSRESX,5";
#postprocess
$FINALRESX=960;
$POSTCMD="-resize2dx \$FINALRESX,5";
#OFDIS params list
#1. Coarsest scale                               (here: 5)
#2. Finest scale                                 (here: 3)
#3/4. Min./Max. iterations                       (here: 12)
#5./6./7. Early stopping parameters
#8. Patch size                                   (here: 8)
#9. Patch overlap                                (here: 0.4)
#10.Use forward-backward consistency             (here: 0/no)
#11.Mean-normalize patches                       (here: 1/yes)
#12.Cost function                                (here: 0/L2)  Alternatives: 1/L1, 2/Huber, 10/NCC
#13.Use TV refinement                            (here: 1/yes)
#14./15./16. TV parameters alpha,gamma,delta     (here 10,10,5)
#17. Number of TV outer iterations               (here: 1)
#18. Number of TV solver iterations              (here: 3)
#19. TV SOR value                                (here: 1.6)
#20. Verbosity                                   (here: 2) Alternatives: 0/no output, 1/only flow runtime, 2/total runtime
$OFDIS_COARSE=5;
$OFDIS_FINE=1;      #minimum 0
$OFDIS_ITER=36;
$OFDIS_PATCH=12;    #8 ou 12
$OFDIS_OVERLAP=1;   #mettre 1
$OFDIS_CONSISTENCY=1;
$OFDIS_NORMALIZE=1;
$OFDIS_COST=2;
$OFDIS_USETV=2;
$OFDIS_TVOUTERITER=1;   #augmenter pour meilleure qualite
$OFDIS_TVSOLVERITER=3;
$OFDISPARAMS="$OFDIS_COARSE $OFDIS_FINE $OFDIS_ITER $OFDIS_ITER 0.05 0.95 0 $OFDIS_PATCH $OFDIS_OVERLAP $OFDIS_CONSISTENCY $OFDIS_NORMALIZE $OFDIS_COST $OFDIS_USETV 10 10 5 $OFDIS_TVOUTERITER $OFDIS_TVSOLVERITER 1.6 2";
#clean working dir
$CLEAN=1;
$CSV=0;
#do houdini files
$DOHOUDINI=0;
#gpu id
$GPU=0;
$OFFSET=1;
#JSON
$CAPACITY=1000;
$SKIP="-force";
$FPT=5;
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
open (AUTOCONF,">","opticalflow_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0 -> deepflow\n";
print AUTOCONF confstr(OPENCV_DEEPFLOW);
print AUTOCONF "#1 -> flownet2\n";
print AUTOCONF "#2 -> OFDIS : DenseInverseSearch\n";
print AUTOCONF "#3 -> EPPM : EdgePreserving\n";
print AUTOCONF "#4 -> RIC : Robust interpolation of Correspondances\n";
print AUTOCONF "#5 -> PWC-Net : Pyramid, Warping, and Cost Volume\n";
print AUTOCONF "#6 -> Unflow  : Unsupervised Learning with a Bidirectional Census Loss\n";
print AUTOCONF "#7 -> Spynet  : Spatial Pyramid Network\n";
print AUTOCONF "#8 -> Simpleflow  : Sublinear Optical Flow (opencv)\n";
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
#print AUTOCONF confstr(FIRSTFRAME);
#print AUTOCONF confstr(LASTFRAME);
print AUTOCONF "\$FIRSTFRAME=\$FSTART\;\n";
print AUTOCONF "\$LASTFRAME=\$FEND\;\n";
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(DOFLOW);
print AUTOCONF confstr(DORELIABLE);
print AUTOCONF confstr(DOCOLORFLOW);
print AUTOCONF confstr(NORMALISATION);
print AUTOCONF confstr(DOEXR);
print AUTOCONF confstr(DOSEQUENTIAL);
print AUTOCONF confstr(DOREFILL);
print AUTOCONF confstr(REFILLMETHOD);
print AUTOCONF "#0=low-connectivity average\n";
print AUTOCONF "#1=high-connectivity average\n";
print AUTOCONF "#2=low-connectivity median\n";
print AUTOCONF "#3=high-connectivity median\n";
print AUTOCONF confstr(PROCESSRESX);
print AUTOCONF "\$PRECMD=\"\-resize2dx \$PROCESSRESX,5\"\;\n";
print AUTOCONF confstr(FINALRESX);
print AUTOCONF "\$POSTCMD=\"\-resize2dx \$FINALRESX,5\"\;\n";
print AUTOCONF "#size for EPPM\n";
print AUTOCONF confstr(SIZEX);
print AUTOCONF confstr(SIZEY);
print AUTOCONF confstr(OFDISPARAMS);
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
	print "-zeropad4 [1]\n";
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
    print "writing auto.conf : mv opticalflow_auto.conf opticalflow.conf\n";
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
if ($userName eq "dev" || $userName eq "render")	#
  {
  $CPM="/shared/foss/CPM/build/CPM";
  $RIC="/shared/foss/Ric/RIC";
  $EPPM="/shared/foss/EPPM/build/runeppm";
  $OFDIS="/shared/foss/OF_DIS/build/run_OF_RGB";
  $DEEPMATCH="/shared/foss/deepmatching_1.2.2_c++/deepmatching";
  $DEEPFLOW2="/shared/foss/deep-flow/deep_flow2/deepflow2";
  $DEEPFLOW_OPENCV="/shared/foss/FlowCode/build/deepflow_opencv";
  $FLOWNET2="/shared/foss/flownet2/scripts/run-flownet.py";
  $CAFFEMODEL="/shared/foss/flownet2/models/FlowNet2/FlowNet2_weights.caffemodel.h5";
  $DEPLOYPROTO="/shared/foss/flownet2/models/FlowNet2/FlowNet2_deploy.prototxt.template";
  #$FLO2EXR="/shared/Scripts/bin/flo2exr";
  #$EXR2FLO="/shared/Scripts/bin/exr2flo";
  $FLO2EXR="/shared/foss/FlowCode/build/flo2exr";
  $EXR2FLO="/shared/foss/FlowCode/build/exr2flo";
  $COLOR_FLOW="/shared/Scripts/bin/color_flow";
  $CONSISTENCYCHECK="/shared/foss/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/shared/foss/gmic/src/gmic";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  $ENV{PYTHONPATH} = "/shared/foss/flownet2/python:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss/flownet2/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  $ENV{PATH} = "/shared/foss/flownet2/build/tools:/shared1/foss/flownet2/build/scripts:$ENV{'PATH'}";
  $ENV{CAFFE_BIN} = "/shared/foss/flownet2/build/tools/caffe";
  }
  
if ($userName eq "dev18")	#
  {
  $CPM="/shared/foss-18/CPM/build/CPM";
  $RIC="/shared/foss-18/Ric/build/RIC";
  $EPPM="/shared/foss-18/EPPM/build/runeppm";
  $OFDIS="/shared/foss-18/OF_DIS/build/run_OF_RGB";
  $DEEPMATCH="/shared/foss-18/DeepFlow/deepmatching";
  $DEEPFLOW2="/shared/foss-18/DeepFlow/deepflow2";
  $DEEPFLOW_OPENCV="/shared/foss-18/FlowCode/build/deepflow_opencv";
  $FLOWNET2="python3 /shared/foss-18/flownet2/scripts/run-flownet.py";
  $CAFFEMODEL="/shared/foss-18/flownet2/models/FlowNet2/FlowNet2_weights.caffemodel.h5";
  $DEPLOYPROTO="/shared/foss-18/flownet2/models/FlowNet2/FlowNet2_deploy.prototxt.template";
  $PWC="python3 /shared/foss-18/pytorch-pwc/run.py";
  $UNFLOW="python3 /shared/foss-18/pytorch-unflow/run.py";
  $SPYNET="python3 /shared/foss-18/pytorch-spynet/run.py";
  $SIMPLEFLOW="/shared/foss-18/FlowCode/build/simpleflow_opencv run";
  #$FLO2EXR="/shared/Scripts/bin/flo2exr";
  #$EXR2FLO="/shared/Scripts/bin/exr2flo";
  $FLO2EXR="/shared/foss/FlowCode/build/flo2exr";
  $EXR2FLO="/shared/foss/FlowCode/build/exr2flo";
  $COLOR_FLOW="/shared/Scripts/bin/color_flow";
  $CONSISTENCYCHECK="/shared/foss-18/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/usr/bin/gmic";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  $ENV{PYTHONPATH} = "/shared/foss-18/flownet2/python:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/flownet2/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  $ENV{PATH} = "/shared/foss-18/flownet2/build/tools:/shared1/foss/flownet2/build/scripts:$ENV{'PATH'}";
  $ENV{CAFFE_BIN} = "/shared/foss-18/flownet2/build/tools/caffe";
  }
  
if ($userName eq "lulu") # Nanterre
  {
  $DEEPMATCH="/mnt/shared/v16/deepmatching_1.2.2_c++/deepmatching";
  $DEEPFLOW2="/mnt/shared/v16/deep-flow/deep_flow2/deepflow2";
  $FLOWNET2="/mnt/shared/v16/flownet2/scripts/run-flownet.py";
  $CAFFEMODEL="/mnt/shared/v16/flownet2/models/FlowNet2/FlowNet2_weights.caffemodel.h5";
  $DEPLOYPROTO="/mnt/shared/v16/flownet2/models/FlowNet2/FlowNet2_deploy.prototxt.template";
  $FLO2EXR="/mnt/shared/v16/bin/flo2exr";
  $EXR2FLO="/mnt/shared/v16/bin/exr2flo";
  $COLOR_FLOW="/mnt/shared/v16/bin/color_flow";
  $CONSISTENCYCHECK="/mnt/shared/v16/artistic-videos//consistencyChecker/consistencyChecker";
  $GMIC="/usr/bin/gmic";
  $HSCRIPT = "/shared/apps/houdini/hfs15.5.673/bin/hscript";
  $ENV{PYTHONPATH} = "/mnt/shared/v16/flownet2/python:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/mnt/shared/v16/flownet2/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  $ENV{PATH} = "/mnt/shared/v16/flownet2/build/tools:/mnt/shared/v16/flownet2/build/scripts:$ENV{'PATH'}";
  $ENV{CAFFE_BIN} = "/mnt/shared/v16/flownet2/build/tools/caffe";
  }
  
print "PYTHONPATH : $ENV{'PYTHONPATH'}\n";
print "LD_LIBRARY_PATH : $ENV{'LD_LIBRARY_PATH'}\n";
print "PATH : $ENV{'PATH'}\n";
print "CAFFE : $ENV{'CAFFE_BIN'}\n";
    
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
    
for ($i = $FSTART ;$i < $FEND ;$i++)
{
#-----------------------------#
($s1,$m1,$h1)=localtime(time);
#-----------------------------#
$j=$i+$OFFSET;
#$k=$i-$OFFSET;

$ii=sprintf("%04d",$i);
$jj=sprintf("%04d",$j);
#$kk=sprintf("%04d",$k);

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

$FORWARD="$OOUTDIR/dual/forward_$ii\_$jj.flo";
$BACKWARD="$OOUTDIR/dual/backward_$jj\_$ii.flo";
$COLORFORWARD="$OOUTDIR/dual/forward_$ii\_$jj.png";
$COLORBACKWARD="$OOUTDIR/dual/backward_$jj\_$ii.png";
$EXRFORWARD="$OOUTDIR/dual/forward_$ii\_$jj.exr";
$EXRBACKWARD="$OOUTDIR/dual/backward_$jj\_$ii.exr";
$EXRFORWARDREFILL="$OOUTDIR/dual/forward_refill_$ii\_$jj.exr";
$EXRBACKWARDREFILL="$OOUTDIR/dual/backward_refill_$jj\_$ii.exr";

#sequential
$NEXT="$OOUTDIR/sequential/next.$ii.flo";
$PREV="$OOUTDIR/sequential/prev.$jj.flo";
$COLORNEXT="$OOUTDIR/sequential/next_flowcolor.$ii.png";
$COLORPREV="$OOUTDIR/sequential/prev_flowcolor.$jj.png";
$EXRNEXT="$OOUTDIR/sequential/next.$ii.exr";
$EXRPREV="$OOUTDIR/sequential/prev.$jj.exr";
$EXRNEXTREFILL="$OOUTDIR/sequential/next_refill.$ii.exr";
$EXRPREVREFILL="$OOUTDIR/sequential/prev_refill.$jj.exr";

#preprocess
$WORKDIR="$OOUTDIR/w$ii";
if ($METHOD == 3)
    {
    $WFILE1="$WORKDIR/$IN.$ii.ppm";
    $WFILE2="$WORKDIR/$IN.$jj.ppm";
    }
else
    {
    $WFILE1="$WORKDIR/$IN.$ii.$EXT";
    $WFILE2="$WORKDIR/$IN.$jj.$EXT";
    }
$WFORWARD="$WORKDIR/forward.flo";
$WBACKWARD="$WORKDIR/backward.flo";
$WFORWARDEXR="$WORKDIR/forward.exr";
$WBACKWARDEXR="$WORKDIR/backward.exr";

if (-e $FORWARD && !$FORCE)
    {print BOLD RED "frame $ii exists ... skipping\n";print RESET;}
else
    {
    #touch
    $touchcmd="touch $FORWARD";
    system $touchcmd;
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
    if ($DOFLOW)
        {
        if ($FINALRESX != $PROCESSRESX)
            {
            if ($METHOD == 1)
                {
                $cmd="$FLOWNET2 --gpu $GPU $CAFFEMODEL $DEPLOYPROTO $WFILE1 $WFILE2 $WFORWARD $LOG1";
                }
            if ($METHOD == 0)
                {
                if ($OPENCV_DEEPFLOW)
                    {
                    $cmd="$DEEPFLOW_OPENCV -g $WFILE1 $WFILE2 $WFORWARD";
                    }
                else
                    {
                    $cmd="$DEEPMATCH $WFILE1 $WFILE2 -nt 0 | $DEEPFLOW2 $WFILE1 $WFILE2 $WFORWARD -match -sintel $LOG1";
                    }
                }
            if ($METHOD == 2)
                {
                $cmd="$OFDIS $WFILE1 $WFILE2 $WFORWARD $OFDISPARAMS";
                }
            if ($METHOD == 3)
                {
                $cmd="$EPPM $WFILE1 $WFILE2 $SIZEX $SIZEY $WFORWARD";
                }
            if ($METHOD == 4)
                {
                $cmd="$CPM $WFILE1 $WFILE2 $WORKDIR/cpm.txt;$RIC $WFILE1 $WFILE2 $WORKDIR/cpm.txt $WFORWARD";
                }
            if ($METHOD == 5)
                {
                $cmd="$PWC --model $PWCMODEL --first $WFILE1 --second $WFILE2 --out $WFORWARD";
                }
            if ($METHOD == 6)
                {
                $cmd="$UNFLOW --model css --first $WFILE1 --second $WFILE2 --out $WFORWARD";
                }
            if ($METHOD == 7)
                {
                $cmd="$SPYNET --model $SPYMODEL --first $WFILE1 --second $WFILE2 --out $WFORWARD";
                }
            if ($METHOD == 8)
                {
                $cmd="$SIMPLEFLOW  $WFILE1 $WFILE2 $WFORWARD";
                }
            verbose($cmd);
            print("--------> opticalflow forward [$ii->$jj methode $METHOD]\n");
            system $cmd;
            #convert flo to exr
            $cmd="$FLO2EXR $WFORWARD $WFORWARDEXR $LOG1";
            verbose($cmd);
            print("--------> flo2exr  forward [resizing]\n");
            system $cmd;
            #resize exr to finalres
            $MOTIONRATIO=$FINALRESX/$PROCESSRESX;
            $cmd="$GMIC -i $WFORWARDEXR $POSTCMD -mul $MOTIONRATIO -o $WFORWARDEXR $LOG2";
            verbose($cmd);
            print("--------> resizing [$POSTCMD motionratio:$MOTIONRATIO]\n");
            system $cmd;
            #reconvert resized to flo
            $cmd="$EXR2FLO $WFORWARDEXR $FORWARD $LOG1";
            verbose($cmd);
            print("--------> exr2flo forward [resizing]\n");
            system $cmd;
            }
        else
            {
            if ($METHOD == 1)
                {
                $cmd="$FLOWNET2 --gpu $GPU $CAFFEMODEL $DEPLOYPROTO $WFILE1 $WFILE2 $FORWARD $LOG1";
                }
            if ($METHOD == 0)
                {
                if ($OPENCV_DEEPFLOW)
                    {
                    $cmd="$DEEPFLOW_OPENCV -g $WFILE1 $WFILE2 $FORWARD";
                    }
                else 
                    {
                    $cmd="$DEEPMATCH $WFILE1 $WFILE2 -nt 0 | $DEEPFLOW2 $WFILE1 $WFILE2 $FORWARD -match -sintel $LOG1";
                    }
                }
            if ($METHOD == 2)
                {
                $cmd="$OFDIS $WFILE1 $WFILE2 $FORWARD $OFDISPARAMS";
                }
            if ($METHOD == 3)
                {
                $cmd="$EPPM $WFILE1 $WFILE2 $SIZEX $SIZEY $FORWARD";
                }
            if ($METHOD == 4)
                {
                $cmd="$CPM $WFILE1 $WFILE2 $WORKDIR/cpm.txt;$RIC $WFILE1 $WFILE2 $WORKDIR/cpm.txt $FORWARD";
                }
            if ($METHOD == 5)
                {
                $cmd="$PWC --model $PWCMODEL --first $WFILE1 --second $WFILE2 --out $FORWARD";
                }
            if ($METHOD == 6)
                {
                $cmd="$UNFLOW --model css --first $WFILE1 --second $WFILE2 --out $FORWARD";
                }
            if ($METHOD == 7)
                {
                $cmd="$SPYNET --model $SPYMODEL --first $WFILE1 --second $WFILE2 --out $FORWARD";
                }
            if ($METHOD == 8)
                {
                $cmd="$SIMPLEFLOW  $WFILE1 $WFILE2 $FORWARD";
                }
            verbose($cmd);
            print("--------> opticalflow forward [$ii->$jj methode $METHOD]\n");
            system $cmd;
            }
        }
    #exr
    if ($DOEXR)
      {
      $cmd="$FLO2EXR $FORWARD $EXRFORWARD $LOG1";
      verbose($cmd);
      print("--------> flo2exr  forward [$ii->$jj]");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            $cmd="cp $EXRFORWARD $EXRNEXT";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      if ($i == $LASTFRAME)
        {
        $cmd="$GMIC -i $EXRFORWARD -mul[0] 0 -o $OOUTDIR/sequential/next.$ii.exr $LOG2";
        verbose($cmd);
        print("--------> sequential/next.$ii.exr is a black frame\n");
        system $cmd;
        }
      }
    #flowcolor
    if ($DOCOLORFLOW)
      {
      $cmd="$COLOR_FLOW $FORWARD $COLORFORWARD $NORMALISATION $LOG2";
      verbose($cmd);
      print("--------> colorflow forward [$ii->$jj]");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            $cmd="cp $COLORFORWARD $COLORNEXT";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      }
    #flow : bug a rajouter ne pas faire le backward si on est a la derniere frame !
    if ($DOFLOW)
        {
        if ($FINALRESX != $PROCESSRESX)
            {
            if ($METHOD == 1)
                {
                $cmd="$FLOWNET2 --gpu $GPU $CAFFEMODEL $DEPLOYPROTO $WFILE2 $WFILE1 $WBACKWARD $LOG1";
                }
            if ($METHOD == 0)
                {
                if ($OPENCV_DEEPFLOW)
                    {
                    $cmd="$DEEPFLOW_OPENCV -g $WFILE2 $WFILE1 $WBACKWARD";
                    }
                else
                    {
                    $cmd="$DEEPMATCH $WFILE2 $WFILE1 -nt 0 | $DEEPFLOW2 $WFILE2 $WFILE1 $WBACKWARD -match -sintel $LOG1";
                    }
                }
            if ($METHOD == 2)
                {
                $cmd="$OFDIS $WFILE2 $WFILE1 $WBACKWARD $OFDISPARAMS";
                }
            if ($METHOD == 3)
                {
                $cmd="$EPPM $WFILE2 $WFILE1 $SIZEX $SIZEY $WBACKWARD";
                }
            if ($METHOD == 4)
                {
                $cmd="$CPM $WFILE2 $WFILE1 $WORKDIR/cpm.txt;$RIC $WFILE2 $WFILE1 $WORKDIR/cpm.txt $WBACKWARD";
                }
            if ($METHOD == 5)
                {
                $cmd="$PWC --model $PWCMODEL --first $WFILE2 --second $WFILE1 --out $WBACKWARD";
                }
            if ($METHOD == 6)
                {
                $cmd="$UNFLOW --model css --first $WFILE2 --second $WFILE1 --out $WBACKWARD";
                }
            if ($METHOD == 7)
                {
                $cmd="$SPYNET --model $SPYMODEL --first $WFILE2 --second $WFILE1 --out $WBACKWARD";
                }
            if ($METHOD == 8)
                {
                $cmd="$SIMPLEFLOW  $WFILE2 $WFILE1 $WBACKWARD";
                }
            verbose($cmd);
            print("--------> opticalflow backward [$jj->$ii methode $METHOD]\n");
            system $cmd;
            #convert flo to exr
            $cmd="$FLO2EXR $WBACKWARD $WBACKWARDEXR $LOG1";
            verbose($cmd);
            print("--------> flo2exr backward [resizing]\n");
            system $cmd;
            #resize exr to finalres
            $MOTIONRATIO=$FINALRESX/$PROCESSRESX;
            verbose("motion ratio : $MOTIONRATIO");
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
        else
            {
            if ($METHOD == 1)
                {
                $cmd="$FLOWNET2 --gpu $GPU $CAFFEMODEL $DEPLOYPROTO $WFILE2 $WFILE1 $BACKWARD $LOG1";
                }
            if ($METHOD == 0)
                {
                if ($OPENCV_DEEPFLOW)
                    {
                    $cmd="$DEEPFLOW_OPENCV -g $WFILE2 $WFILE1 $BACKWARD";
                    }
                else
                    {
                    $cmd="$DEEPMATCH $WFILE2 $WFILE1 -nt 0 | $DEEPFLOW2 $WFILE2 $WFILE1 $BACKWARD -match -sintel $LOG1";
                    }
                }
            if ($METHOD == 2)
                {
                $cmd="$OFDIS $WFILE2 $WFILE1 $BACKWARD $OFDISPARAMS";
                }
            if ($METHOD == 3)
                {
                $cmd="$EPPM $WFILE2 $WFILE1 $SIZEX $SIZEY $BACKWARD";
                }
            if ($METHOD == 4)
                {
                $cmd="$CPM $WFILE2 $WFILE1 $WORKDIR/cpm.txt;$RIC $WFILE2 $WFILE1 $WORKDIR/cpm.txt $BACKWARD";
                }
            if ($METHOD == 5)
                {
                $cmd="$PWC --model $PWCMODEL --first $WFILE2 --second $WFILE1 --out $BACKWARD";
                }
            if ($METHOD == 6)
                {
                $cmd="$UNFLOW --model css --first $WFILE2 --second $WFILE1 --out $BACKWARD";
                }
            if ($METHOD == 7)
                {
                $cmd="$SPYNET --model $SPYMODEL --first $WFILE2 --second $WFILE1 --out $BACKWARD";
                }
            if ($METHOD == 8)
                {
                $cmd="$SIMPLEFLOW  $WFILE2 $WFILE1 $BACKWARD";
                }
            verbose($cmd);
            print("--------> opticalflow backward [$jj->$ii methode $METHOD]\n");
            system $cmd;
            }
        }
    #exr
    if ($DOEXR)
      {
      $cmd="$FLO2EXR $BACKWARD $EXRBACKWARD $LOG1";
      verbose("flow2exr backward : frame $jj->$ii");
      verbose($cmd);
      print("--------> flo2exr backward [$jj->$ii]");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            $cmd="cp $EXRBACKWARD $EXRPREV";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      if ($i == $FIRSTFRAME)
        {
        $cmd="$GMIC -i $EXRBACKWARD -mul[0] 0 -o $OOUTDIR/sequential/prev.$ii.exr $LOG2";
        verbose($cmd);
        print("--------> sequential/prev.$ii.exr is a black frame\n");
        system $cmd;
        }
      }
    #flowcolor
    if ($DOCOLORFLOW)
      {
      $cmd="$COLOR_FLOW $BACKWARD $COLORBACKWARD $NORMALISATION $LOG2";
      verbose($cmd);
      print("--------> colorflow backward [$jj->$ii]");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            $cmd="cp $COLORBACKWARD $COLORPREV";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      }
    #reliable
    if ($DORELIABLE)
      {
      $consistencycmd="$CONSISTENCYCHECK $BACKWARD $FORWARD $OOUTDIR/dual/reliable_$jj\_$ii.pgm $LOG1";
      verbose($consistencycmd);
      print("--------> consistency backward [$jj->$ii]");
      system $consistencycmd;
      $cmd="$GMIC $OOUTDIR/dual/reliable_$jj\_$ii.pgm -o $OOUTDIR/dual/reliable_$jj\_$ii.png $LOG2";
      verbose($cmd);
      print(" [+convert to png]\n");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            #$cmd="cp $OOUTDIR/dual/reliable_$jj\_$ii.pgm $OOUTDIR/sequential/reliableprev.$jj.pgm";
            $cmd="$GMIC $OOUTDIR/dual/reliable_$jj\_$ii.pgm -o $OOUTDIR/sequential/reliableprev.$jj.png $LOG2";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      if ($i == $FIRSTFRAME)
        {
        $cmd="$GMIC -i $OOUTDIR/dual/reliable_$jj\_$ii.pgm -mul 0 -o $OOUTDIR/sequential/reliableprev.$ii.png $LOG2";
        verbose($cmd);
        print("--------> sequential/reliableprev.$ii.pgm is a black frame\n");
        system $cmd;
        }
      $consistencycmd="$CONSISTENCYCHECK $FORWARD $BACKWARD $OOUTDIR/dual/reliable_$ii\_$jj.pgm $LOG1";
      verbose($consistencycmd);
      print("--------> consistency forward  [$ii->$jj]");
      system $consistencycmd;
      $cmd="$GMIC $OOUTDIR/dual/reliable_$ii\_$jj.pgm -o $OOUTDIR/dual/reliable_$ii\_$jj.png $LOG2";
      verbose($cmd);
      print(" [+convert to png]\n");
      system $cmd;
      if ($DOSEQUENTIAL)
            {
            #$cmd="cp $OOUTDIR/dual/reliable_$ii\_$jj.pgm $OOUTDIR/sequential/reliablenext.$ii.pgm";
            $cmd="$GMIC $OOUTDIR/dual/reliable_$ii\_$jj.pgm -o $OOUTDIR/sequential/reliablenext.$ii.png $LOG2";
            verbose($cmd);
            print(" [+sequential]\n");
            system $cmd;
            }
      if ($i == $LASTFRAME)
        {
        $cmd="$GMIC -i $OOUTDIR/dual/reliable_$ii\_$jj.pgm -mul 0 -o $OOUTDIR/sequential/reliablenext.$ii.png $LOG2";
        verbose($cmd);
        print("--------> sequential/reliablenext.$ii.pgm is a black frame\n");
        system $cmd;
        }
      #from MakeOptFlow.h
      #eval $flowCommandLine "$file1" "$file2" "${folderName}/forward_${i}_${j}.flo"
      #eval $flowCommandLine "$file2" "$file1" "${folderName}/backward_${j}_${i}.flo"
      #./consistencyChecker/consistencyChecker "${folderName}/backward_${j}_${i}.flo" "${folderName}/forward_${i}_${j}.flo" "${folderName}/reliable_${j}_${i}.pgm"
      #./consistencyChecker/consistencyChecker "${folderName}/forward_${i}_${j}.flo" "${folderName}/backward_${j}_${i}.flo" "${folderName}/reliable_${i}_${j}.pgm"
      }
    if ($DOREFILL)
        {
        $cmd="$GMIC $EXRFORWARD $OOUTDIR/dual/reliable_$ii\_$jj.pgm -le[1] 250 --inpaint[0] [1],0,$REFILLMETHOD -o[2] $EXRFORWARDREFILL $LOG2";
        verbose($cmd);
        print("--------> refill dual next $ii->$jj\n");
        system $cmd;
        $cmd="$GMIC $EXRBACKWARD $OOUTDIR/dual/reliable_$jj\_$ii.pgm -le[1] 250 --inpaint[0] [1],0,$REFILLMETHOD -o[2] $EXRBACKWARDREFILL $LOG2";
        verbose($cmd);
        print("--------> refill dual prev $jj->$ii\n");
        system $cmd;
        }
    if ($CLEAN)
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
