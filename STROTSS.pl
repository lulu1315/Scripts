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
$CONTINUE=-1;
$FSTEP=1;
$SHOT="";
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$FLOWDIR="$CWD/opticalflow";
$COHERENTDIR="$CWD/coherent";
$CONTENTBLEND="5e-1";
$DOEDGES=0;
$EDGEDIR="$CWD/edges";
$EDGES="edges";
$EDGEDILATE=0;
$EDGESMOOTH=1;
$EDGESOPACITY=1;
$EDGESMODE="add";
$EDGESINVERT=0;
$DOGRADIENT=0;
$GRADIENTWEIGHT=0;
$DOTANGENT=0;
$TANGENTWEIGHT=0;
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
#$DOGUIDANCE=0;
#$STYLEGUIDANCE="style_guidance.jpg";
$GUIDANCEDIR="$CWD/guidance";
$GUIDANCE="guidance";
$GUIDANCESIZE=1500;
$COLOR1="255,0,0";
$COLOR2="0,255,0";
$COLOR3="0,0,255";
$OUTDIR="$CWD/$scriptname";
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
#hyperparameter
$SIZE=1280; #input size , final size is given by max scale
#size must be coherent with optical flow size
$MAX_SCALE=6;
$CONTENT_WEIGHT=.5;
$WEIGHT_DECAY=2; #weight change at each scale
$MAX_ITERS=500;
$LOSS_TRESHOLD=1e-5;
#preprocess
$CONTENTBLUR=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOCOLORTRANSFERT=3;
$LCTMODE="pca";
#reindex result
$DOINDEX=0;
$INDEXCOLOR=64;
$INDEXMETHOD=1;
$DITHERING=1;
$INDEXROLL=5;
$DOLOCALCONTRAST=0;
$DONOISE=0;
$NOISETYPE=0;
$NOISESTRENGTH=1;
$NOISESCALE=100;
$NOISEGRADBLUR=3;
$NOISEGRADTRESHOLD=.2;
#postprocess
$DOMEDIANFILTER=0;
$MEDIANRADIUS=2;
$MEDIANREPEAT=1;
$CLEAN=1;
$CSV=0;
$CSVFILE="./SHOTLIST.csv";
#gpu id
$GPU=0; #-1 -> CPU only 0 -> GPU
$LOG1=" > /var/tmp/strotss_$GPU.log";
$LOG2=" 2> /var/tmp/strotss_$GPU.log";

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
print AUTOCONF confstr(CONTINUE);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(FLOWDIR);
print AUTOCONF confstr(COHERENTDIR);
print AUTOCONF confstr(CONTENTBLEND);
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF confstr(DOGRADIENT);
print AUTOCONF confstr(GRADIENTWEIGHT);
print AUTOCONF confstr(DOTANGENT);
print AUTOCONF confstr(TANGENTWEIGHT);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#guidance\n";
#print AUTOCONF confstr(DOGUIDANCE);
#print AUTOCONF confstr(STYLEGUIDANCE);
print AUTOCONF confstr(GUIDANCEDIR);
print AUTOCONF confstr(GUIDANCE);
print AUTOCONF confstr(GUIDANCESIZE);
print AUTOCONF "#hyperparameter\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(MAX_SCALE);
print AUTOCONF confstr(CONTENT_WEIGHT);
print AUTOCONF confstr(WEIGHT_DECAY);
print AUTOCONF confstr(MAX_ITERS);
print AUTOCONF confstr(LOSS_TRESHOLD);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(CONTENTBLUR);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(DOCOLORTRANSFERT);
print AUTOCONF "#0 : no transfert\n";
print AUTOCONF "#1 : color_transfer\n";
print AUTOCONF "#2 : hmap\n";
print AUTOCONF "#3 : Neural-tools\n";
print AUTOCONF "#reindex\n";
print AUTOCONF confstr(DOINDEX);
print AUTOCONF confstr(INDEXCOLOR);
print AUTOCONF confstr(INDEXMETHOD);
print AUTOCONF confstr(DITHERING);
print AUTOCONF confstr(INDEXROLL);
print AUTOCONF "#4 : ideepcolor\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(NOISE);
print AUTOCONF confstr(NOISETYPE);
print AUTOCONF confstr(NOISESTRENGTH);
print AUTOCONF confstr(NOISESCALE);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DOMEDIANFILTER);
print AUTOCONF confstr(MEDIANRADIUS);
print AUTOCONF confstr(MEDIANREPEAT);
print AUTOCONF "#more\n";
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(CSV);
print AUTOCONF "#gpu id\n";
print AUTOCONF confstr(GPU);
print AUTOCONF "\$PARAMS=\"_cw\$CONTENT_WEIGHT\";\n";
print AUTOCONF "1\n";
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
    print "-gpu gpu_id [0]\n";
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
    if (-e "$STYLEDIR") {print "$STYLEDIR already exists\n";}
    else {$cmd="mkdir $STYLEDIR";system $cmd;}
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
  if (@ARGV[$arg] eq "-style") 
    {
    $STYLE=@ARGV[$arg+1];
    print "style $STYLE\n";
    }
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shot $SHOT\n";
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
  if (@ARGV[$arg] eq "-gpu") 
    {
    $GPU=@ARGV[$arg+1];
    $LOG1=" > /var/tmp/$scriptname\_$GPU.log";
    $LOG2=" 2> /var/tmp/$scriptname\_$GPU.log";
    print "gpu id : $GPU\n";
    }
  if (@ARGV[$arg] eq "-size") 
    {
    $SIZE=@ARGV[$arg+1];
    print "size : $SIZE\n";
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
  $STROTSS="python3 /shared/foss-18/STROTSS/styleTransfer.py";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss-18/color_transfer/color_transfer.py";
  $HMAP="/shared/foss-18/hmap/hmap.py";
  $LINEARCOLORTRANSFERT="python3 /shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $PREVIOUS_WARP="/shared/foss-18/opencv-code/warper/build/previous_warp";
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }

sub strotss {

#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    if ($IN_USE_SHOT) {$AUTODIR="$CONTENTDIR/$SHOT";} else {$AUTODIR="$CONTENTDIR";}
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
    
print ("debug : $CONTINUE\n");
if ($CONTINUE == -1) {$CONTINUE = $FSTART};
print ("debug : $FSTART $FEND\n");

$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

$pid=$$;
#multistyle
@STYLE=split(/\,/,$STYLE);
$stylenumber=@STYLE;
if ($stylenumber > 1)
    {
    $DOGUIDANCE=1;
    $WORKSTYLEDIR="$OOUTDIR/w_$pid";
    if (-e "$WORKSTYLEDIR") {print "$WORKSTYLEDIR already exists\n";}
    else {$cmd="mkdir $WORKSTYLEDIR";system $cmd;}
    if ($stylenumber == 2)
        {
        $STYLE1=@STYLE[0];
        $STYLE2=@STYLE[1];
        $SSTYLE1=$STYLE1;
        $SSTYLE1=~ s/.jpg//;
        $SSTYLE1=~ s/.jpeg//;
        $SSTYLE1=~ s/.png//;
        $SSTYLE1=~ s/\.//;
        $SSTYLE2=$STYLE2;
        $SSTYLE2=~ s/.jpg//;
        $SSTYLE2=~ s/.jpeg//;
        $SSTYLE2=~ s/.png//;
        $SSTYLE2=~ s/\.//;
        $SSTYLE="$SSTYLE1\_$SSTYLE2";
        print "$stylenumber styles : $STYLE1 $STYLE2 $SSTYLE\n";
        #concatstyle
        $cmd="gmic $STYLEDIR/$STYLE1 $STYLEDIR/$STYLE2 -to_colormode 3 -resize2dy $GUIDANCESIZE --montage H -o[2] $WORKSTYLEDIR/style.png -remove[2] -fill_color[0] $COLOR1 -fill_color[1] $COLOR2 -montage H -o $WORKSTYLEDIR/style_guidance.png";
        print "$cmd\n";
        system $cmd;
        }
    if ($stylenumber == 3)
        {
        $STYLE1=@STYLE[0];
        $STYLE2=@STYLE[1];
        $STYLE3=@STYLE[2];
        $SSTYLE1=$STYLE1;
        $SSTYLE1=~ s/.jpg//;
        $SSTYLE1=~ s/.jpeg//;
        $SSTYLE1=~ s/.png//;
        $SSTYLE1=~ s/\.//;
        $SSTYLE2=$STYLE2;
        $SSTYLE2=~ s/.jpg//;
        $SSTYLE2=~ s/.jpeg//;
        $SSTYLE2=~ s/.png//;
        $SSTYLE2=~ s/\.//;
        $SSTYLE3=$STYLE3;
        $SSTYLE3=~ s/.jpg//;
        $SSTYLE3=~ s/.jpeg//;
        $SSTYLE3=~ s/.png//;
        $SSTYLE3=~ s/\.//;
        $SSTYLE="$SSTYLE1\_$SSTYLE2\_$SSTYLE3";
        print "$stylenumber styles : $STYLE1 $STYLE2 $STYLE3 $SSTYLE\n";
        #concatstyle
        $cmd="gmic $STYLEDIR/$STYLE1 $STYLEDIR/$STYLE2 $STYLEDIR/$STYLE3 -to_colormode 3 -resize2dy $GUIDANCESIZE --montage H -o[3] $WORKSTYLEDIR/style.png -remove[3] -fill_color[0] $COLOR1 -fill_color[1] $COLOR2 -fill_color[2] $COLOR3 -montage H -o $WORKSTYLEDIR/style_guidance.png";
        print "$cmd\n";
        system $cmd;
        }
    #$STYLEDIR="$WORKSTYLEDIR";
    $STYLE="style.png";
    $STYLEGUIDANCE="style_guidance.png";
    #exit;
    }
else
    {
    #finalframe
    $SSTYLE=$STYLE;
    $SSTYLE=~ s/.jpg//;
    $SSTYLE=~ s/.jpeg//;
    $SSTYLE=~ s/.png//;
    $SSTYLE=~ s/\.//;
    }
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];

$TAG="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS";
if (-e $TAG && !$FORCE)
   {print BOLD RED "frame $TAG exists ... skipping\n";print RESET;}
else
  {
  $touchcmd="touch $TAG";
  system $touchcmd;
  
    for ($i=$CONTINUE ; $i <= $FEND ; $i=$i+$FSTEP)
    {

    if ($ZEROPAD == 4)
        {
        $ii=sprintf("%04d",$i);
        $jj=sprintf("%04d",$i-1);
        }
    if ($ZEROPAD == 5)
        {
        $ii=sprintf("%05d",$i);
        $jj=sprintf("%05d",$i-1);
        }

    if ($IN_USE_SHOT) 
        {$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";} 
    else 
        {$INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXT";}
    
    $INEDGES  ="$EDGEDIR/$SHOT/$EDGES.$ii.$EXT";
    $OFLOW="$FLOWDIR/$SHOT/dual/backward_$ii\_$jj.exr";
    $CONSISTENCY="$FLOWDIR/$SHOT/dual/reliable_$ii\_$jj.png";
    $GRADIENT="$COHERENTDIR/$SHOT/gradient.$ii.exr";
    $TANGENT="$COHERENTDIR/$SHOT/tangent.$ii.exr";
    #working dir
    $WORKDIR="$OOUTDIR/w$ii\_$pid";
    #work elements
    $WCONTENT  ="$WORKDIR/preprocess.$EXT";
    $WCOLOR    ="$WORKDIR/colortransfert.$EXT";
    $WCOLOR1    ="$WORKDIR/colortransfert1.$EXT";
    $WCOLOR2    ="$WORKDIR/colortransfert2.$EXT";
    $WCOLOR3    ="$WORKDIR/colortransfert3.$EXT";
    $WNOISE    ="$WORKDIR/noise.$EXT";
    $WEDGES    ="$WORKDIR/edges.$EXT";
    $WNEURAL   ="$WORKDIR/neural.$EXT";
    $WPREVIOUS ="$WORKDIR/previous.$EXT";
    $WGUIDE    ="$WORKDIR/guide.$EXT";
    $WFLOW     ="$WORKDIR/flow.exr";
    #output
    $FINALFRAME="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";

  print BOLD BLUE ("\nframe : $ii\n");print RESET;
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #preprocessing content --> $WCONTENT
  if ($CONTENTBLUR != 0) 
    {$GMIC1="-fx_sharp_abstract $CONTENTBLUR,10,0.5,0,0";} else {$GMIC1="";}
  if (($BRIGHTNESS != 0) || ($CONTRAST != 0) || ($GAMMA != 0) || ($SATURATION != 0)) 
    {$GMIC2="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC2="";}
  if ($DOLOCALCONTRAST) 
    {$GMIC3="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC3="";}
  $cmd="$GMIC -i $INCONTENT $GMIC1 -resize2dx $SIZE $GMIC2 $GMIC3 -to_colormode 3 -o $WCONTENT $LOG2";
  print("--------> preprocess [blur:$CONTENTBLUR b/c/g/s:$BRIGHTNESS,$CONTRAST,$GAMMA,$SATURATION lce:$DOLOCALCONTRAST]\n");
  verbose($cmd);
  system $cmd;
  
#process edges --> $WEDGES
if($DOEDGES)
  {
  if ($EDGEDILATE != 0) 
    {$GMIC1="-dilate $EDGEDILATE";} else {$GMIC1="";}
  if ($EDGESMOOTH != 0) 
    {$GMIC2="-fx_dreamsmooth 10,0,1,1,0,0.8,0,24,0";} else {$GMIC2="";}
  if ($EDGESINVERT != 0) 
    {$GMIC3="-n 0,1 -oneminus -n 0,255";} else {$GMIC3="";}
  $cmd="$GMIC -i $INEDGES -to_colormode 3 $GMIC1 -resize2dx $SIZE,5 $GMIC2 $GMIC3 -o $WEDGES $LOG2";
  print("--------> preprocess edges [dilate:$EDGEDILATE dreamsmooth:$EDGESMOOTH]\n");
  verbose($cmd);
  system $cmd;
#add edges
  $cmd="$GMIC -i $WCOLOR -i $WEDGES -blend $EDGESMODE,$EDGESOPACITY -o $WCOLOR $LOG2";
#  $cmd="$GMIC -i $WCOLOR -i $WEDGES -n[1] 0,1 -oneminus[1] -n[1] 0,255 -blend multiply,$EDGESOPACITY -o $WCOLOR $LOG2";
  print("--------> add edges [mode:$EDGESMODE opacity:$EDGESOPACITY]\n");
  verbose($cmd);
  system $cmd;
  }
  
if (($DONOISE != 0) && ($i == $FSTART)) 
  {
  #$cmd="$GMIC -i $WCOLOR -fx_noise $NOISE,0,0,1,0 -o $WCOLOR $LOG2";
  #print("--------> add noise [noise intensity:$NOISE]\n");
  $cmd="$GMIC -i $WCONTENT -fx_emulate_grain $NOISETYPE,1,$NOISESTRENGTH,$NOISESCALE,0,0,0,0,0,0,0,0 -b $NOISEGRADBLUR -o $WNOISE $LOG2";
  verbose($cmd);
  system $cmd;
  $cmd="$GMIC -i $WCONTENT -b $NOISEGRADBLUR -luminance -gradient_norm -le $NOISEGRADTRESHOLD -b $NOISEGRADBLUR $WCONTENT $WNOISE -blend_fade[1,2] [0] -o[1] $WCONTENT $LOG2";
  print("--------> add noise [noise type:$NOISETYPE strength:$NOISESTRENGTH scale:$NOISESCALE]\n");
  verbose($cmd);
  system $cmd;
  }
#color transfert --> $WCOLOR
  if ($DOCOLORTRANSFERT == 0)
    {
    verbose("no color transfert");
    $cmd="cp $WCONTENT $WCOLOR";
    #$cmd="$GMIC -i $WCONTENT -to_colormode 1 -o $WCOLOR $LOG2";
    print("--------> no color transfert []\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 1)
    {
    verbose("color transfert : using color_transfer");
    $cmd="python $COLOR_TRANSFER -s $STYLEDIR/$STYLE -t $WCONTENT -o $WCOLOR";
    print("--------> color_transfer [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 2)
    {
    verbose("color transfert : using hmap");
    $cmd="python $HMAP $WCONTENT $STYLEDIR/$STYLE $WCOLOR";
    print("--------> hmap [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }
  if ($DOCOLORTRANSFERT == 3)
    {
    if ($stylenumber == 1)
        {
        verbose("color transfert : using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE --output_image $WCOLOR";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        }
    if ($stylenumber == 2)
        {
        verbose("color transfert style1 $STYLE1: using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE1 --output_image $WCOLOR1";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE1 -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR1 -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR1 $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        verbose("color transfert style2 $STYLE2: using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE2 --output_image $WCOLOR2";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE2 -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR2 -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR2 $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        #recompose colortransfert
        $cmd = "$GMIC $WCOLOR1 $WCOLOR2 $GUIDANCEDIR/$SHOT/$GUIDANCE.$ii.$EXT -split[2] c -div[2,3] 255 -mul[0] [2] -mul[1] [3] -remove[2,3,4] -add -o $WCOLOR";
        verbose($cmd);
        print("--------> recombining colortransfers 1 2\n");
        system $cmd;
        #copy guide
        $cmd="cp $GUIDANCEDIR/$SHOT/$GUIDANCE.$ii.$EXT $WGUIDE";
        system $cmd;
        }
    if ($stylenumber == 3)
        {
        verbose("color transfert style1 $STYLE1: using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE1 --output_image $WCOLOR1";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE1 -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR1 -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR1 $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        verbose("color transfert style2 $STYLE2: using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE2 --output_image $WCOLOR2";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE2 -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR2 -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR2 $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        verbose("color transfert style3 $STYLE3: using neural-tools");
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $WCONTENT --source_image $STYLEDIR/$STYLE3 --output_image $WCOLOR3";
        print("--------> neural-tools [mode:$LCTMODE style:$STYLE]\n");
        verbose($cmd);
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $STYLEDIR/$STYLE3 -colormap $INDEXCOLOR,$INDEXMETHOD,1 $WCOLOR3 -index[1] [0],$DITHERING,1 -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $WCOLOR3 $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        #recompose colortransfert
        $cmd = "$GMIC $WCOLOR1 $WCOLOR2 $WCOLOR3 $GUIDANCEDIR/$SHOT/$GUIDANCE.$ii.$EXT -split[3] c -div[3,4,5] 255 -mul[0] [3] -mul[1] [4] -mul[2] [5] -remove[3,4,5] -add -o $WCOLOR";
        verbose($cmd);
        print("--------> recombining colortransfers 1 2 3\n");
        system $cmd;
        #copy guide
        $cmd="cp $GUIDANCEDIR/$SHOT/$GUIDANCE.$ii.$EXT $WGUIDE";
        system $cmd;
        }
    }
  if ($DOCOLORTRANSFERT == 4)
    {
    verbose("color transfert : using ideepcolor");
    $cmd="$IDEEPCOLOR $WCONTENT $STYLEDIR/$STYLE $WCOLOR $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL 2> /var/tmp/cnnmrf_$GPU.log";
    #$cmd="$IDEEPCOLOR $WCONTENT $STYLEDIR/$STYLE $WCOLOR $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL";
    print("--------> ideepcolor [style:$STYLE]\n");
    verbose($cmd);
    system $cmd;
    }

#warp previous and blend
if ($i != $FSTART)
  {
  #tangent and or gradient
  if ($DOGRADIENT)
    {
    $FLOMIC1="$GRADIENT -mul[-1] $GRADIENTWEIGHT -add"; 
    }
  else {$FLOMIC1="";}
  if ($DOTANGENT)
    {
    $FLOMIC2="$TANGENT -mul[-1] $TANGENTWEIGHT -add"; 
    }
  else {$FLOMIC2="";}
  #add flow vectors
  $flowcmd="gmic $OFLOW $FLOMIC1 $FLOMIC2 -resize2dx $SIZE -o $WFLOW";
  verbose($flowcmd);
  system $flowcmd;
  #resize previous result
  $cmd="gmic $OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$jj.$EXT -resize2dx $SIZE -o $WPREVIOUS";
  verbose($cmd);
  system $cmd;
  #warp
  $cmd="$PREVIOUS_WARP $WCOLOR $WPREVIOUS $WFLOW $CONSISTENCY $CONTENTBLEND $WCOLOR";
  print("--------> warping previous result [content blend:$CONTENTBLEND]\n");
  verbose($cmd);
  system $cmd;
  }
#process transfer
    if (!$DOGUIDANCE)
        {
        $cmd="$STROTSS $WCOLOR $STYLEDIR/$STYLE $WNEURAL $CONTENT_WEIGHT $MAX_SCALE $SIZE $WEIGHT_DECAY $MAX_ITERS $LOSS_TRESHOLD";
        print("--------> strotss [content weight:$CONTENT_WEIGHT max scale:$MAX_SCALE target size:$SIZE]\n");
        verbose($cmd);
        }
    else
        {
        $cmd="$STROTSS $WCOLOR $WORKSTYLEDIR/$STYLE $WNEURAL $CONTENT_WEIGHT $MAX_SCALE $SIZE $WEIGHT_DECAY  $MAX_ITERS $LOSS_TRESHOLD -gr $GUIDANCEDIR/$SHOT/$GUIDANCE.$ii.$EXT $WORKSTYLEDIR/$STYLEGUIDANCE";
        print("--------> guided strotss [content weight:$CONTENT_WEIGHT max scale:$MAX_SCALE target size:$SIZE]\n");
        verbose($cmd);
        }   
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  system $cmd;
  #postprocess
  if ($DOMEDIANFILTER) 
    {$GMIC1="-iain_recursive_median_p $MEDIANRADIUS,$MEDIANREPEAT,0,0,1";} else {$GMIC1="";}
  $cmd="$GMIC -i $WNEURAL $GMIC1 -o $WNEURAL $LOG2";
  verbose($cmd);
  system $cmd;
  #final
  $cmd="cp $WNEURAL $FINALFRAME";
  verbose($cmd);
  system $cmd;
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  print BOLD YELLOW "\nWriting  STROTSS $ii took $hlat:$mlat:$slat \n";print RESET;
  #-----------------------------#
  }
}
if ($CLEAN && $DOGUIDANCE)
    {
    $cleancmd="rm -r $WORKSTYLEDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
}#strotss sub

#main
if ($CSV)
  {
  open (CSV , "$CSVFILE");
  while ($line=<CSV>)
    {
    chop $line;
    @line=split(/,/,$line);
    $SHOT=@line[0];
    $STYLE=@line[1];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $CONTINUE = @line[7];
    if ($process)
      {
      strotss();
      }
    }
   }
else
  {
  strotss();
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
