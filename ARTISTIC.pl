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
$SHOT="";
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$FLOWDIR="$CWD/opticalflow";
#$FLOW="backward";
$FLOWWEIGHT="reliable";
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$STYLESCALE="5e-1";
$DOCOLORTRANSFERT=0;
$LCTMODE="pca";
$DOEDGES=0;
$EDGEDIR="$CWD/edges";
$EDGES="edges";
$EDGEDILATE=0;
$EDGESMOOTH=1;
$EDGESOPACITY=1;
$EDGESMODE="subtract";
$EDGESINVERT=0;
$DOGRADIENT=0;
$GRADIENTDIR="$CWD/gradient";
$GRADIENT="gradient";
$GRADIENTBOOSTER=1;
$DOTANGENT=0;
$TANGENTDIR="$CWD/gradient";
$TANGENT="tangent";
$TANGENTBOOSTER=1;
$OUTDIR="$CWD/artistic";
$OUTPUT_SIZE=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$PROCESS=0;
$FORCE=0;
#0:light pass 1:multipass 2:mono pass
#network
$NUMITERATIONS="2000,1000";
$STYLEWEIGHT=2000;
$CONTENTWEIGHT=1;
$CONTENTBLEND="5e-1";
$CONTENTBLUR=0;
$TEMPORALWEIGHT="1e3";
$TVWEIGHT="1e-4";
$POOLING="avg";
$OPTIMIZER="adam";
$LEARNING_RATE="5e-1";
$NORMALIZE_GRADIENT=1;
$SEED=-1;
$INIT="image,prevWarped";
#gpu id
$GPU=0;
$PARAMS="_lr$LEARNING_RATE\_$POOLING\_$OPTIMIZER\_ng$NORMALIZE_GRADIENT";
$CSV=0;
$LOG1=" > /var/tmp/artistic_$GPU.log";
$LOG2=" 2> /var/tmp/artistic_$GPU.log";

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
open (AUTOCONF,">","artistic_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(FLOWDIR);
print AUTOCONF confstr(FLOWWEIGHT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(STYLESCALE);
print AUTOCONF confstr(DOCOLORTRANSFERT);
print AUTOCONF "#0 : no transfert\n";
print AUTOCONF "#1 : color_transfer NOT IMPLEMENTED\n";
print AUTOCONF "#2 : hmap NOT IMPLEMENTED\n";
print AUTOCONF "#3 : Neural-tools\n";
print AUTOCONF "#4 : ideepcolor NOT IMPLEMENTED\n";
print AUTOCONF "#5 : index color\n";
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF confstr(DOGRADIENT);
print AUTOCONF confstr(GRADIENTDIR);
print AUTOCONF confstr(GRADIENT);
print AUTOCONF confstr(GRADIENTBOOSTER);
print AUTOCONF confstr(DOTANGENT);
print AUTOCONF confstr(TANGENTDIR);
print AUTOCONF confstr(TANGENT);
print AUTOCONF confstr(TANGENTBOOSTER);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUTPUT_SIZE);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(PROCESS);
print AUTOCONF "#0:light 1:multipass 2:single pass\n";
print AUTOCONF "#network\n";
print AUTOCONF confstr(NUMITERATIONS);
print AUTOCONF confstr(STYLEWEIGHT);
print AUTOCONF confstr(CONTENTWEIGHT);
print AUTOCONF confstr(CONTENTBLEND);
print AUTOCONF confstr(CONTENTBLUR);
print AUTOCONF confstr(TEMPORALWEIGHT);
print AUTOCONF confstr(TVWEIGHT);
print AUTOCONF confstr(POOLING);
print AUTOCONF confstr(OPTIMIZER);
print AUTOCONF confstr(LEARNING_RATE);
print AUTOCONF confstr(NORMALIZE_GRADIENT);
print AUTOCONF confstr(SEED);
print AUTOCONF confstr(INIT);
print AUTOCONF confstr(CSV);
print AUTOCONF confstr(GPU);
print AUTOCONF "\$PARAMS=\"_lr\$LEARNING_RATE\\_\$POOLING\\_\$OPTIMIZER\\_ng\$NORMALIZE_GRADIENT\"\;\n";
print AUTOCONF "1\n";
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-help\n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
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
    print "writing artistic_auto.conf --> mv artistic_auto.conf artistic.conf\n";
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
  if (@ARGV[$arg] eq "-gpu") 
    {
    $GPU=@ARGV[$arg+1];
    $LOG1=" > /var/tmp/artistic_$GPU.log";
    $LOG2=" 2> /var/tmp/artistic_$GPU.log";
    print "gpu id : $GPU\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
    }
  if (@ARGV[$arg] eq "-size") 
    {
    $SIZE=@ARGV[$arg+1];
    print "size : $RESIZE\n";
    }
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file : $CSVFILE\n";
    $CSV=1;
    }
  }
  
$userName =  $ENV{'USER'}; 
if (($userName eq "dev") || ($userName eq "render"))	#
  {
  $GMIC="/usr/bin/gmic";
  $LUA="/shared/foss/artistic-videos/artistic_video_dev.lua";
  $LIGHTLUA="/shared/foss/artistic-videos/artistic_video_light.lua";
  $MULTILUA="/shared/foss/artistic-videos/artistic_video_multiPass_dev.lua";
  $TH="/shared/foss/torch-multi/install/bin/th";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="/shared/foss/Neural-Tools/linear-color-transfer.py";
  $ENV{PYTHONPATH} = "/shared/foss/caffe/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }

if ($userName eq "dev18") #
  {
  $GMIC="/usr/bin/gmic";
  $LUA="/shared/foss-18/artistic-videos/artistic_video_dev.lua";
  $LIGHTLUA="/shared/foss-18/artistic-videos/artistic_video_light.lua";
  $MULTILUA="/shared/foss-18/artistic-videos/artistic_video_multiPass_dev.lua";
  $TH="/shared/foss-18/torch/install/bin/th";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  $COLOR_TRANSFER="/shared/foss-18/color_transfer/color_transfer.py";
  $HMAP="/shared/foss-18/hmap/hmap.py";
  $LINEARCOLORTRANSFERT="/shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
sub neural {

#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    $AUTODIR="$CONTENTDIR/$SHOT";
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
    
#style
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
#content
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];

$NUMIMAGES=$FEND-$FSTART+1;

$CONTENTPATTERN="$CONTENTDIR/$SHOT/$CONTENT.%04d.$EXT";
$EDGESPATTERN="$EDGEDIR/$SHOT/$EDGES.%04d.$EXT";
$FLOWPATTERN="$FLOWDIR/$SHOT/dual/backward_[\%04d]_{\%04d}.flo";
$FLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
if ($DOGRADIENT)
    {
    $GRADIENTPATTERN="$GRADIENTDIR/$SHOT/$GRADIENT.{\%04d}.flo";
    }
if ($DOTANGENT)
    {
    $TANGENTPATTERN="$TANGENTDIR/$SHOT/$TANGENT.{\%04d}.flo";
    }

$FORWARDFLOWPATTERN="$FLOWDIR/$SHOT/dual/forward_[\%04d]_{\%04d}.flo";
$BACKWARDFLOWPATTERN="$FLOWDIR/$SHOT/dual/backward\_[\%04d]_{\%04d}.flo";
$FORWARDFLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
$BACKWARDFLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";

$OOUTDIR="$OUTDIR/$SHOT/";
$OUT="$CCONTENT\_$SSTYLE$PARAMS.png";

if (-e "$OOUTDIR/$OUT" && !$FORCE)
   {print BOLD RED "sequence $OUT exists ... skipping\n";print RESET;}
else
  {
print BOLD YELLOW "Output ----> $OUT [$NUMIMAGES images] Shot : $SHOT\n";print RESET;
if (-e "$OOUTDIR") 
    {print "$OOUTDIR already exists\n";}
else 
    {$cmd="mkdir $OOUTDIR";system $cmd;}
    
$touchcmd="touch $OOUTDIR/$OUT";
system $touchcmd;

if ($PROCESS == 0)
{
$cmd="$TH $LIGHTLUA -pid $$ -start_number $FSTART -num_images $NUMIMAGES -seed $SEED -tv_weight $TVWEIGHT -num_iterations $NUMITERATIONS -init $INIT -pooling $POOLING -optimizer $OPTIMIZER -learning_rate $LEARNING_RATE -style_scale $STYLESCALE -content_pattern $CONTENTPATTERN -flow_pattern $FLOWPATTERN -flowWeight_pattern $FLOWWEIGHTPATTERN -style_weight $STYLEWEIGHT -content_weight $CONTENTWEIGHT -content_blend $CONTENTBLEND -temporal_weight $TEMPORALWEIGHT -output_folder $OOUTDIR -output_image $OUT -style_image $STYLEDIR/$STYLE -gpu $GPU -number_format \%04d -output_size $OUTPUT_SIZE -content_blur $CONTENTBLUR";
if ($NORMALIZE_GRADIENT) {$cmd=$cmd." -normalize_gradients";}
if ($DOCOLORTRANSFERT) {$cmd=$cmd." -docolortransfer $DOCOLORTRANSFERT";}
if ($DOEDGES) 
    {
    $cmd=$cmd." -doedges -edges_pattern $EDGESPATTERN -edgesopacity $EDGESOPACITY -edgesmode $EDGESMODE -edgedilate $EDGEDILATE";
    if ($EDGESMOOTH) {$cmd=$cmd." -edgesmooth";}
    if ($EDGESINVERT) {$cmd=$cmd." -edgesinvert";}
    }
if ($DOGRADIENT) {$cmd=$cmd." -dogradient -gradient_pattern $GRADIENTPATTERN -gradientbooster $GRADIENTBOOSTER";}
if ($DOTANGENT) {$cmd=$cmd." -dotangent -tangent_pattern $TANGENTPATTERN -tangentbooster $TANGENTBOOSTER";}
}
    
if ($PROCESS == 1)
    {
@tmp=split(/,/,$NUMITERATIONS);
$NUMITERATIONSMULTI=@tmp[0];
@tmp=split(/,/,$INIT);
$INITMULTI=@tmp[1];
$cmd="$TH $MULTILUA -start_number $FSTART -num_images $NUMIMAGES -seed $SEED -tv_weight $TVWEIGHT -num_iterations $NUMITERATIONSMULTI -init $INITMULTI -pooling $POOLING -optimizer $OPTIMIZER -learning_rate $LEARNING_RATE -style_scale $STYLESCALE -content_pattern $CONTENTPATTERN -forwardFlow_pattern $FORWARDFLOWPATTERN -backwardFlow_pattern $BACKWARDFLOWPATTERN -forwardFlow_weight_pattern $FORWARDFLOWWEIGHTPATTERN -backwardFlow_weight_pattern $BACKWARDFLOWWEIGHTPATTERN -style_weight $STYLEWEIGHT -content_weight $CONTENTWEIGHT -temporal_weight $TEMPORALWEIGHT -output_folder $OOUTDIR -output_image $OUT -style_image $STYLEDIR/$STYLE -backend cudnn -gpu $GPU -cudnn_autotune -number_format \%04d";
if ($NORMALIZE_GRADIENT) {$cmd=$cmd." -normalize_gradients";}
    }
    
if ($PROCESS == 2)
    {
$cmd="$TH $LUA -start_number $FSTART -num_images $NUMIMAGES -seed $SEED -tv_weight $TVWEIGHT -num_iterations $NUMITERATIONS -init $INIT -pooling $POOLING -optimizer $OPTIMIZER -learning_rate $LEARNING_RATE -style_scale $STYLESCALE -content_pattern $CONTENTPATTERN -flow_pattern $FLOWPATTERN -flowWeight_pattern $FLOWWEIGHTPATTERN -style_weight $STYLEWEIGHT -content_weight $CONTENTWEIGHT -content_blend $CONTENTBLEND -temporal_weight $TEMPORALWEIGHT -output_folder $OOUTDIR -output_image $OUT -style_image $STYLEDIR/$STYLE -backend cudnn -gpu $GPU -cudnn_autotune -number_format \%04d";
if ($NORMALIZE_GRADIENT) {$cmd=$cmd." -normalize_gradients";}
    }
verbose $cmd;
system $cmd;
}
}#neural sub

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
    $STYLESCALE=@line[2];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $suffix=@line[7];
    if ($process)
      {
      neural();
      }
    }
   }
else
  {
  neural();
  }

# gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    #print ("key1 = $key1\n");
    #print ("key2 = $key2\n");
    #print ("keycount = $keycount\n");
    #print ("KEYFRAME = $KEYFRAME\n");
    return $key1+$keycount*(($key2-$key1)/$KEYFRAME);
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
