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
$SHOT="";
$CONTENT_USE_SHOT=0;
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$FLOWDIR="$CWD/opticalflow";
#$FLOW="backward";
$USE_REFILL=1;
$FLOWWEIGHT="reliable";
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$STYLESCALE=1;
#2 pass
$DO2PASS=1;
$LOWDEF=512;
$STYLE_LOWDEF="style.jpg";
$STYLESCALELOWDEF=1;
$DOCOLORTRANSFERT=1;
#reindex result
$DOINDEX=0;
$INDEXCOLOR=64;
$INDEXMETHOD=1;
$DITHERING=1;
$INDEXROLL=5;
$DOEDGES=0;
$EDGEDIR="$CWD/coherent";
$EDGES="coherent";
$EDGEDILATE=0;
$EDGESMOOTH=1;
$EDGESOPACITY=.5;
$EDGESMODE="subtract";
$EDGESINVERT=1;
$DOGRADIENT=0;
$GRADIENTDIR="$CWD/coherent";
$GRADIENT="gradient";
$GRADIENTBOOSTER=1;
$DOTANGENT=0;
$TANGENTDIR="$CWD/coherent";
$TANGENT="tangent";
$TANGENTBOOSTER=1;
$DOCUSTOM=0;
$CUSTOMDIR="$CWD/customflow";
$CUSTOM="custom";
$CUSTOMBOOSTER=1;
$MASKOPTICALFLOW=0;
$MASKDIR="$CWD/masks";
$MASK="mask";
$OUTDIR="$CWD/artistic";
$OUTPUT_SIZE=0;
#
$SHAVE=0;
$SHAVEX=$SHAVE;
$SHAVEY=$SHAVE;
$EXPAND=0;
$EXPANDX=$EXPAND;
$EXPANDY=$EXPAND;
#preprocess
$DOLOCALCONTRAST=1;
$ANISOTROPIC=0;
$EQUALIZE=0;
$EQUALIZEMIN="20%";
$EQUALIZEMAX="80%";
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$NOISE=0;
$HISTOGRAMTRANSFER=0;
#
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$FORCE=0;
#network
$NUMITERATIONS="600,300";
$RECOLORITER=20;
$STYLEWEIGHT=2000;
$CONTENTWEIGHT=1;
$CONTENTBLEND="5e-1";
$CONTENTBLUR=0;
$TEMPORALWEIGHT="1e3";
$TVWEIGHT="1e-4";
$POOLING="avg";
$OPTIMIZER="adam";
$LEARNING_RATE="5e-1";
$BETA1="9e-1";
$EPSILON="1e-8";
$NORMALIZE_GRADIENT=1;
$SEED=-1;
$INIT="image,prevWarped";


#gpu id
$GPU=0;
$PARAMS="_ssc$STYLESCALE\_$POOLING\_$OPTIMIZER\_ng$NORMALIZE_GRADIENT";
$CSV=0;
$CSVFILE="./SHOTLIST.csv";
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
print AUTOCONF confstr(CONTENT_USE_SHOT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(FLOWDIR);
print AUTOCONF confstr(USE_REFILL);
#print AUTOCONF confstr(FLOWWEIGHT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(STYLESCALE);
print AUTOCONF confstr(DO2PASS);
print AUTOCONF confstr(LOWDEF);
print AUTOCONF confstr(STYLE_LOWDEF);
print AUTOCONF confstr(STYLESCALELOWDEF);

print AUTOCONF "\n#edges\n";
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF "\n#gradient flow\n";
print AUTOCONF confstr(DOGRADIENT);
print AUTOCONF confstr(GRADIENTBOOSTER);
print AUTOCONF confstr(GRADIENTDIR);
print AUTOCONF confstr(GRADIENT);

print AUTOCONF "\n#tangent flow\n";
print AUTOCONF confstr(DOTANGENT);
print AUTOCONF confstr(TANGENTBOOSTER);
print AUTOCONF confstr(TANGENTDIR);
print AUTOCONF confstr(TANGENT);

print AUTOCONF "\n#custom flow\n";
print AUTOCONF confstr(DOCUSTOM);
print AUTOCONF confstr(CUSTOMBOOSTER);
print AUTOCONF confstr(CUSTOMDIR);
print AUTOCONF confstr(CUSTOM);

print AUTOCONF "\n#mask optical flow\n";
print AUTOCONF confstr(MASKOPTICALFLOW);
print AUTOCONF confstr(MASKDIR);
print AUTOCONF confstr(MASK);

print AUTOCONF "\n#geometry\n";
print AUTOCONF confstr(SHAVE);
print AUTOCONF "\$SHAVEX=\$SHAVE\;\n";
print AUTOCONF "\$SHAVEY=\$SHAVE\;\n";
print AUTOCONF confstr(EXPAND);
print AUTOCONF "\$EXPANDX=\$EXPAND\;\n";
print AUTOCONF "\$EXPANDY=\$EXPAND\;\n";
print AUTOCONF "\n#preprocess\n";
print AUTOCONF confstr(CONTENTBLUR);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF confstr(EQUALIZEMIN);
print AUTOCONF confstr(EQUALIZEMAX);
print AUTOCONF confstr(DOCOLORTRANSFERT);
#print AUTOCONF "#index color\n";
#print AUTOCONF confstr(DOINDEX);
#print AUTOCONF confstr(INDEXCOLOR);
#print AUTOCONF confstr(INDEXMETHOD);
#print AUTOCONF confstr(DITHERING);
#print AUTOCONF confstr(INDEXROLL);
print AUTOCONF confstr(HISTOGRAMTRANSFER);
print AUTOCONF confstr(ANISOTROPIC);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(NOISE);

print AUTOCONF "\n#hyper parameters\n";
print AUTOCONF confstr(NUMITERATIONS);
print AUTOCONF confstr(LEARNING_RATE);
print AUTOCONF confstr(TVWEIGHT);
print AUTOCONF confstr(RECOLORITER);
print AUTOCONF "#recolor content every ..\n";
print AUTOCONF confstr(STYLEWEIGHT);
print AUTOCONF confstr(CONTENTWEIGHT);
print AUTOCONF confstr(CONTENTBLEND);
print AUTOCONF confstr(TEMPORALWEIGHT);
print AUTOCONF confstr(POOLING);
print AUTOCONF confstr(OPTIMIZER);
print AUTOCONF confstr(BETA1);
print AUTOCONF confstr(EPSILON);
print AUTOCONF confstr(NORMALIZE_GRADIENT);
print AUTOCONF confstr(SEED);
print AUTOCONF confstr(INIT);

print AUTOCONF "\n#output\n";
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUTPUT_SIZE);

print AUTOCONF "\@tmp=split(/,/,\$NUMITERATIONS)\;\n";
print AUTOCONF "\$PARAMS=\"_ssc\$STYLESCALE\\_\$STYLESCALELOWDEF\\_lr\$LEARNING_RATE\\_iter\@tmp[0]\"\;\n";
#print AUTOCONF "\$PARAMS=\"_lr\$LEARNING_RATE\\_\$POOLING\\_\$OPTIMIZER\\_ng\$NORMALIZE_GRADIENT\"\;\n";

print AUTOCONF "\n#misc\n";
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(CSV);
print AUTOCONF confstr(GPU);
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
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad : $ZEROPAD\n";
    }
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shot : $SHOT\n";
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
  if (@ARGV[$arg] eq "-continue") 
    {
    $CONTINUE=@ARGV[$arg+1];
    print "continuing at frame : $CONTINUE\n";
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

if (($userName eq "dev18") || ($userName eq "render"))	#
  {
  $GMIC="/shared/foss-18/gmic-2.8.3_pre/build/gmic";
  $LUA="/shared/foss-18/artistic-videos/artistic_video.lua";
  $LUA2PASS="/shared/foss-18/artistic-videos/artistic_video_2pass.lua";
  if ($HOSTNAME =~ "v8") {$TH="/shared/foss-18/torch-amd/install/bin/th";}
  if ($HOSTNAME =~ "hp") {$TH="/shared/foss-18/torch/install/bin/th";}
  if ($HOSTNAME =~ "s005" || $HOSTNAME =~ "s006") {$TH="/shared/foss-18/torch_GTX1080/install/bin/th";}
  if ($HOSTNAME =~ "s001" || $HOSTNAME =~ "s002" || $HOSTNAME =~ "s003" || $HOSTNAME =~ "etalo") {$TH="/shared/foss-18/torch/install/bin/th";}
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
sub neural {

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
    
print ("debug : continue $CONTINUE\n");
if ($CONTINUE == -1) 
    {
    $CONTINUE_WITH = 1;
    $NUMIMAGES=$FEND-$FSTART+1;
    }
else 
    {
    $CONTINUE_WITH =$CONTINUE-$FSTART+1;
    $NUMIMAGES=$FEND-$CONTINUE+1;
    }
print ("debug : start $FSTART end $FEND continue_with $CONTINUE_WITH numimages $NUMIMAGES\n");

#style
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
#style lowdef
$SSTYLELOWDEF=$STYLE_LOWDEF;
$SSTYLELOWDEF=~ s/.jpg//;
$SSTYLELOWDEF=~ s/.jpeg//;
$SSTYLELOWDEF=~ s/.png//;
$SSTYLELOWDEF=~ s/\.//;
#content
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];

if ($USE_REFILL) {$FLOWFLAG="refill";}
else {$FLOWFLAG="dual";}

if ($CONTENT_USE_SHOT)
    {
    $CONTENTPATTERN="$CONTENTDIR/$SHOT/$CONTENT.%04d.$EXT";
    }
else
    {
    $CONTENTPATTERN="$CONTENTDIR/$CONTENT.%04d.$EXT";
    }
if ($IN_USE_SHOT)
    {
    $EDGESPATTERN="$EDGEDIR/$SHOT/$EDGES.%04d.$EXT";
    $FLOWPATTERN="$FLOWDIR/$SHOT/$FLOWFLAG/backward_[\%04d]_{\%04d}.flo";
    $FLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    $FORWARDFLOWPATTERN="$FLOWDIR/$SHOT/$FLOWFLAG/forward_[\%04d]_{\%04d}.flo";
    $BACKWARDFLOWPATTERN="$FLOWDIR/$SHOT/$FLOWFLAG/backward\_[\%04d]_{\%04d}.flo";
    $FORWARDFLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    $BACKWARDFLOWWEIGHTPATTERN="$FLOWDIR/$SHOT/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    }
else
    {
    $EDGESPATTERN="$EDGEDIR/$EDGES.%04d.$EXT";
    $FLOWPATTERN="$FLOWDIR/$FLOWFLAG/backward_[\%04d]_{\%04d}.flo";
    $FLOWWEIGHTPATTERN="$FLOWDIR/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    $FORWARDFLOWPATTERN="$FLOWDIR/$FLOWFLAG/forward_[\%04d]_{\%04d}.flo";
    $BACKWARDFLOWPATTERN="$FLOWDIR/$FLOWFLAG/backward\_[\%04d]_{\%04d}.flo";
    $FORWARDFLOWWEIGHTPATTERN="$FLOWDIR/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    $BACKWARDFLOWWEIGHTPATTERN="$FLOWDIR/dual/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
    }

if ($DOGRADIENT)
    {
    $GRADIENTPATTERN="$GRADIENTDIR/$SHOT/$GRADIENT.{\%04d}.flo";
    }
if ($DOTANGENT)
    {
    $TANGENTPATTERN="$TANGENTDIR/$SHOT/$TANGENT.{\%04d}.flo";
    }
if ($DOCUSTOM)
    {
    $CUSTOMPATTERN="$CUSTOMDIR/$SHOT/$CUSTOM.{\%04d}.flo";
    }
if ($MASKOPTICALFLOW)
    {
    $MASKPATTERN="$MASKDIR/$SHOT/$MASK.%04d.$EXT";
    }

$OOUTDIR="$OUTDIR/$SHOT/";
$OUT="$CCONTENT\_$SSTYLELOWDEF\_$SSTYLE$PARAMS.png";

if (-e "$OOUTDIR/$OUT" && !$FORCE)
   {print BOLD RED "sequence $OUT exists ... skipping\n";print RESET;}
else
  {
    print BOLD YELLOW "Output ----> $OUT [$NUMIMAGES images] [Shot: $SHOT]\n";print RESET;
    if (-e "$OOUTDIR") 
        {print "$OOUTDIR already exists\n";}
    else 
        {$cmd="mkdir $OOUTDIR";system $cmd;}
    
    $touchcmd="touch $OOUTDIR/$OUT";
    system $touchcmd;
    
    if ($DO2PASS) {$LUA="/shared/foss-18/artistic-videos/artistic_video_2pass.lua";}
    else {$LUA="/shared/foss-18/artistic-videos/artistic_video.lua";}
    
    $cmd="$TH $LUA -pid $$ -start_number $FSTART -num_images $NUMIMAGES -seed $SEED -tv_weight $TVWEIGHT -num_iterations $NUMITERATIONS -init $INIT -pooling $POOLING -optimizer $OPTIMIZER -learning_rate $LEARNING_RATE -style_scale $STYLESCALE -content_pattern $CONTENTPATTERN -flow_pattern $FLOWPATTERN -flowWeight_pattern $FLOWWEIGHTPATTERN -style_weight $STYLEWEIGHT -content_weight $CONTENTWEIGHT -content_blend $CONTENTBLEND -temporal_weight $TEMPORALWEIGHT -output_folder $OOUTDIR -output_image $OUT -style_image $STYLEDIR/$STYLE -gpu $GPU -number_format \%04d -output_size $OUTPUT_SIZE -content_blur $CONTENTBLUR -shavex $SHAVEX -shavey $SHAVEY -expandx $EXPANDX -expandy $EXPANDY -lce $DOLOCALCONTRAST -equalize $EQUALIZE -equalizemin $EQUALIZEMIN -equalizemax $EQUALIZEMAX -brightness $BRIGHTNESS -contrast $CONTRAST -gamma $GAMMA -saturation $SATURATION -noise $NOISE -continue_with $CONTINUE_WITH -beta1 $BETA1 -epsilon $EPSILON -save_iter $RECOLORITER -anisotropic $ANISOTROPIC -histogramtransfer $HISTOGRAMTRANSFER";
    if ($NORMALIZE_GRADIENT) {$cmd=$cmd." -normalize_gradients";}
    if ($DOCOLORTRANSFERT) {$cmd=$cmd." -docolortransfer $DOCOLORTRANSFERT";}
    if ($DOINDEX) {$cmd=$cmd." -doindex $DOINDEX -indexcolor $INDEXCOLOR -indexmethod $INDEXMETHOD -dithering $DITHERING -indexroll $INDEXROLL";}
    if ($DOEDGES) 
        {
        $cmd=$cmd." -doedges -edges_pattern $EDGESPATTERN -edgesopacity $EDGESOPACITY -edgesmode $EDGESMODE -edgedilate $EDGEDILATE";
        if ($EDGESMOOTH) {$cmd=$cmd." -edgesmooth";}
        if ($EDGESINVERT) {$cmd=$cmd." -edgesinvert";}
        }
    if ($DOGRADIENT) {$cmd=$cmd." -dogradient -gradient_pattern $GRADIENTPATTERN -gradientbooster $GRADIENTBOOSTER";}
    if ($DOTANGENT) {$cmd=$cmd." -dotangent -tangent_pattern $TANGENTPATTERN -tangentbooster $TANGENTBOOSTER";}
    if ($DOCUSTOM) {$cmd=$cmd." -docustom -custom_pattern $CUSTOMPATTERN -custombooster $CUSTOMBOOSTER";}
    if ($MASKOPTICALFLOW) {$cmd=$cmd." -mask -mask_pattern $MASKPATTERN";}
    if ($DO2PASS) {$cmd=$cmd." -lowdef $LOWDEF -style_image_lowdef $STYLEDIR/$STYLE_LOWDEF -style_scale_lowdef $STYLESCALELOWDEF";}
    verbose($cmd);
    system $cmd;
    #}
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
    if (@line[1] ne "") {$STYLE=@line[1];}
    #$STYLE=@line[1];
    if (@line[2] ne "") {$STYLESCALE=@line[2];}
    #$STYLESCALE=@line[2];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $CONTINUE=@line[7];
    if ($CONTINUE eq "") {$CONTINUE = -1}
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
