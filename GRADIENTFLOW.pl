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
@tmp=split(/\./,$scriptname);
$scriptname=lc $tmp[0];
print BOLD BLUE "scriptname : $scriptname\n";print RESET;
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$FSTART=1;
$FEND=100;
$FSTEP=1;
$SHOT="";
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/gradient";
$DOGRADIENT=1;
$GRADIENTOUT="gradient";
$DOTANGENT=1;
$TANGENTOUT="tangent";
$OUT_USE_SHOT=0;
#preprocess
$DOLOCALCONTRAST=0;
$EQUALIZE=0;
$EQUALIZEMIN="20%";
$EQUALIZEMAX="80%";
$ROLLING=2;
$INBLUR=2;
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
$METHOD=2;
$ETFKERNELSIZE=7;
$ETFITERATIONS=3;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
#$EXTIN="\$EXT";
$EXTOUT="exr";
$OUTBLUR=2;
$VERBOSE=0;
$CSV=0;
$CLEAN=1;
$LOG1=">/var/tmp/gradient.log";
$LOG2="2>/var/tmp/gradient.log";
$PARAMS="";
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
open (AUTOCONF,">","gradientflow_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(FSTEP);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(DOGRADIENT);
print AUTOCONF confstr(GRADIENTOUT);
print AUTOCONF confstr(DOTANGENT);
print AUTOCONF confstr(TANGENTOUT);
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
print AUTOCONF "#method\n";
print AUTOCONF confstr(METHOD);
print AUTOCONF "#1 = gmic;\n";
print AUTOCONF confstr(OUTBLUR);
print AUTOCONF "#2 = Edge Tangent Flow (ETF) from Coherent Line drawing;\n";
print AUTOCONF confstr(ETFKERNELSIZE);
print AUTOCONF confstr(ETFITERATIONS);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(PARAMS);
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
	print "-zeropad4 [1]\n";
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
    print "writing gradientflow_auto.conf : mv gradientflow_auto.conf gradientflow.conf\n";
    autoconf();
    exit;
    }
  if (@ARGV[$arg] eq "-conf") 
    {
    $CONF=@ARGV[$arg+1];
    print "using conf file $CONF\n";
    require $CONF;
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
    print "verbose on\n";
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
if ($userName eq "lulu" || $userName eq "dev" || $userName eq "render")	#
  {
  #$GMIC="/usr/bin/gmic";
  $GMIC="/shared/foss/gmic/src/gmic";
  $EXR2FLO="/shared/Scripts/bin/exr2flo";
  $ETF="/shared/foss/Coherent-Line-Drawing/build/ETF-cli";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

sub csv {
for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
{

#
$ii=sprintf("%04d",$i);
#
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
    $WORKDIR="$OOUTDIR/w$ii";
    }
else
    {
    $GOUT="$OUTDIR/$GRADIENTOUT$PARAMS.$ii.$EXTOUT";
    $GFLOUT="$OUTDIR/$GRADIENTOUT$PARAMS.$ii.flo";
    $TOUT="$OUTDIR/$TANGENTOUT$PARAMS.$ii.$EXTOUT";
    $TFLOUT="$OUTDIR/$TANGENTOUT$PARAMS.$ii.flo";
    $WORKDIR="$OUTDIR/w$ii";
    }

if (-e $GOUT && !$FORCE)
   {print BOLD RED "frame $GOUT exists ... skipping\n";print RESET;}
else {
  #touch file
  $touchcmd="touch $GOUT";
  verbose($touchcmd);
  system $touchcmd;
  
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  verbose("processing frame $ii");
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
  if ($METHOD == 1)
  {
  if ($DOGRADIENT)
    {
    $cmd="$GMIC -i $IIN -blur $INBLUR -luminance -gradient 100%,100%,1,1 -a[0,1,2] c -b[0] $OUTBLUR -o $GOUT $LOG2";
    $flocmd="$EXR2FLO $GOUT $GFLOUT";
    verbose($cmd);
    system $cmd;
    verbose($flocmd);
    system $flocmd;
    if ($DOTANGENT)
        {
        $cmd="$GMIC -i $GOUT -to_colormode 3 fill \"cross(I,[0,0,1])\" -o $TOUT $LOG2";
        $flocmd="$EXR2FLO $TOUT $TFLOUT";
        verbose($cmd);
        system $cmd;
        verbose($flocmd);
        system $flocmd;
        }
    }
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #-----------------------------#
    }
  #Coherent edge flow
  if ($METHOD == 2)
  {
    $cmd="$ETF $IIN $ETFKERNELSIZE $ETFITERATIONS $GOUT $TOUT";
    $gflocmd="$EXR2FLO $GOUT $GFLOUT";
    $tflocmd="$EXR2FLO $TOUT $TFLOUT";
    verbose($cmd);
    print("--------> Edge Tangent Flow [kernel:$ETFKERNELSIZE iterations:$ETFITERATIONS]\n");
    system $cmd;
    verbose($gflocmd);
    print("--------> convert gradient to flo format\n");
    system $gflocmd;
    verbose($tflocmd);
    print("--------> convert tangent to flo format\n");
    system $tflocmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #-----------------------------#

  }
  #afanasy parsing format
  print BOLD YELLOW "Writing $GOUT took $hlat:$mlat:$slat\n";print RESET;
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
$CMD="GMIC";
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
    $FILES="$OUTDIR/$SHOT/$OUT.\@####\@.$EXTOUT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP";
    $FILES="$OUTDIR/$OUT.\@####\@.$EXTOUT";
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
