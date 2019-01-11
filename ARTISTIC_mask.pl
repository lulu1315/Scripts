#!/usr/bin/perl
 
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=100;
$SHOT="";
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$SEGMENTATIONDIR="$CWD/otsu";
$SEGMENTATION="ima";
$FLOWDIR="$CWD/opticalflow/dual";
#$FLOW="backward";
$FLOWWEIGHT="reliable";
$STYLEDIR="$CWD/styles";
$STYLE1="style.jpg";
$STYLESCALE1="5e-1";
$STYLE2="style.jpg";
$STYLESCALE2="5e-1";
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
$OUTDIR="$CWD/artistic";
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
$CONTENTBLEND="9e-1";
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
print AUTOCONF confstr(SEGMENTATIONDIR);
print AUTOCONF confstr(SEGMENTATION);
print AUTOCONF confstr(FLOWDIR);
print AUTOCONF confstr(FLOWWEIGHT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE1);
print AUTOCONF confstr(STYLESCALE1);
print AUTOCONF confstr(STYLE2);
print AUTOCONF confstr(STYLESCALE2);
print AUTOCONF confstr(DOCOLORTRANSFERT);
print AUTOCONF confstr(DOEDGES);
print AUTOCONF confstr(EDGEDIR);
print AUTOCONF confstr(EDGES);
print AUTOCONF confstr(EDGEDILATE);
print AUTOCONF confstr(EDGESMOOTH);
print AUTOCONF confstr(EDGESOPACITY);
print AUTOCONF confstr(EDGESMODE);
print AUTOCONF confstr(EDGESINVERT);
print AUTOCONF confstr(OUTDIR);
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
    require $CONF;
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
  $DOUBLELUA="/shared/foss/artistic-videos/artistic_video_doublestyle.lua";
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


sub neural {
#style
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
#content
#$CONTENT="ima_$SSTYLE";
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];

$NUMIMAGES=$FEND-$FSTART+1;

$CONTENTPATTERN="$CONTENTDIR/$CONTENT.%04d.$EXT";
$SEGMENTATIONPATTERN="$SEGMENTATIONDIR/$SEGMENTATION.%04d.$EXT";
$EDGESPATTERN="$EDGEDIR/$EDGES.%04d.$EXT";
#$CONTENTPATTERN="$CONTENTDIR/$SHOT/$CCONTENT.%04d.$EXT";
$FLOWPATTERN="$FLOWDIR/backward_[\%04d]_{\%04d}.flo";
$FLOWWEIGHTPATTERN="$FLOWDIR/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";

$FORWARDFLOWPATTERN="$FLOWDIR/forward_[\%04d]_{\%04d}.flo";
$BACKWARDFLOWPATTERN="$FLOWDIR/backward\_[\%04d]_{\%04d}.flo";
$FORWARDFLOWWEIGHTPATTERN="$FLOWDIR/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";
$BACKWARDFLOWWEIGHTPATTERN="$FLOWDIR/$FLOWWEIGHT\_[\%04d]_{\%04d}.pgm";

$OOUTDIR="$OUTDIR/$SHOT/";
$OUT="$CCONTENT\_$SSTYLE1\_$SSTYLE2$PARAMS.png";

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
    
$cmd="$TH $DOUBLELUA -pid $$ -start_number $FSTART -num_images $NUMIMAGES -seed $SEED -tv_weight $TVWEIGHT -num_iterations $NUMITERATIONS -init $INIT -pooling $POOLING -optimizer $OPTIMIZER -learning_rate $LEARNING_RATE -style_scale1 $STYLESCALE1 -style_scale2 $STYLESCALE2 -content_pattern $CONTENTPATTERN -flow_pattern $FLOWPATTERN -flowWeight_pattern $FLOWWEIGHTPATTERN -style_weight $STYLEWEIGHT -content_weight $CONTENTWEIGHT -content_blend $CONTENTBLEND -temporal_weight $TEMPORALWEIGHT -output_folder $OOUTDIR -output_image $OUT -style_image1 $STYLEDIR/$STYLE1 -style_image2 $STYLEDIR/$STYLE2 -gpu $GPU -number_format \%04d";
if ($NORMALIZE_GRADIENT) {$cmd=$cmd." -normalize_gradients";}
if ($DOCOLORTRANSFERT) {$cmd=$cmd." -docolortransfer -segmentation_pattern $SEGMENTATIONPATTERN";}
if ($DOEDGES) 
    {
    $cmd=$cmd." -doedges -edges_pattern $EDGESPATTERN -edgesopacity $EDGESOPACITY -edgesmode $EDGESMODE -edgedilate $EDGEDILATE";
    if ($EDGESMOOTH) {$cmd=$cmd." -edgesmooth";}
    if ($EDGESINVERT) {$cmd=$cmd." -edgesinvert";}
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
