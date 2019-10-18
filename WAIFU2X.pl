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
$OUTDIR="$CWD/waifu2x";
$OUT="ima";
$OUT_USE_SHOT=0;
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$OP="noise_scale";
$NOISE=3;
$OUTSIZE=0;
$POSTOP="";
$GPU=0;
$CSV=0;
$LOG1=">/var/tmp/waiku_$GPU.log";
$LOG2="2>/var/tmp/waiku_$GPU.log";
#JSON
$CAPACITY=1000;
$SKIP="-force";
$FPT=5;

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
sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

sub autoconf {
open (AUTOCONF,">","waifu_auto.conf");
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
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(OP);
print AUTOCONF confstr(NOISE);
print AUTOCONF confstr(OUTSIZE);
print AUTOCONF confstr(POSTOP);
print AUTOCONF "#flip vertically in nuke if cropping\n";
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CSV);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
    print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
    print "-fstep [1]\n";
	print "-idir dirin\n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-o imageout\n";
	print "-shot shotname\n";
	print "-e image ext (png)\n";
	print "-n noiselevel\n";
	print "-op operation (default noise_scale)\n";
	print "-zeropad [4]\n";
	print "-force\n";
	print "-resize res [output x size]\n";
    print "-gpu gpu_id [0]\n";
	print "-csv csv_file.csv\n";
    print "-json [submit to afanasy]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing waifu_auto.conf : mv waifu_auto.conf waifu.conf\n";
    autoconf();
    if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
    else {$cmd="mkdir $OUTDIR";system $cmd;}
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
  if (@ARGV[$arg] eq "-fstep") 
    {
    $FSTEP=@ARGV[$arg+1];
    print "fstep : $FSTEP\n";
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
  if (@ARGV[$arg] eq "-e") 
    {
    $EXT=@ARGV[$arg+1];
    print "ext : $EXT\n";
    }
  if (@ARGV[$arg] eq "-n") 
    {
    $NOISE=@ARGV[$arg+1];
    print "noise level : $NOISE\n";
    }
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad  $ZEROPAD...\n";
    }
  if (@ARGV[$arg] eq "-op") 
    {
    $OP=@ARGV[$arg+1];
    print "op : $OP\n";
    }
  if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force\n";
    }
  if (@ARGV[$arg] eq "-resize") 
    {
    $OUTSIZE=@ARGV[$arg+1];
    print "outsize : $OUTSIZE\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    $LOG1="";
    $LOG2="";
    print "verbose ...\n";
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
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev" || $userName eq "render")	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $TH="/shared/foss/torch-multi/install/bin/th";
  $LUA="/shared/foss/waifu2x-dev/waifu2x.lua";
  $MODELDIR="/shared/foss/waifu2x-dev/models/anime_style_art_rgb/";
#  $MODELDIR="/shared/foss/waifu2x-dev/models/photo/";
#  $MODELDIR="/shared/foss/waifu2x-dev/models/anime_style_art/";
  }
  
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  if ($HOSTNAME =~ "v8") {$TH="/shared/foss-18/torch-amd/install/bin/th";}
  if ($HOSTNAME =~ "hp") {$TH="/shared/foss-18/torch/install/bin/th";}
  if ($HOSTNAME =~ "s005" || $HOSTNAME =~ "s006") {$TH="/shared/foss-18/torch_GTX1080/install/bin/th";}
  if ($HOSTNAME =~ "s001" || $HOSTNAME =~ "s002" || $HOSTNAME =~ "s003" || $HOSTNAME =~ "etalo") {$TH="/shared/foss-18/torch/install/bin/th";}
  $LUA="/shared/foss-18/waifu2x/waifu2x.lua";
  $MODELDIR="/shared/foss-18/waifu2x/models/anime_style_art_rgb/";
#  $MODELDIR="/shared/foss-18/waifu2x/models/photo/";
#  $MODELDIR="/shared/foss-18/waifu2x/models/anime_style_art/";
  }
  
$GPU++;
  
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    $AUTODIR="$INDIR/$SHOT";
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
    
if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}

sub csv {
for ($i = $FSTART ;$i <= $FEND;$i=$i+$FSTEP)
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
#outdir and final frame
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $OOUT="$OOUTDIR/$OUT.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUT="$OUTDIR/$OUT.$ii.$EXT";
    }
    
if (-e $OOUT && !$FORCE)
{print BOLD RED "frame $OUT.$ii.$EXT exists ... skipping\n";print RESET;}
else
{
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  print BOLD YELLOW ("\nprocessing frame $ii\n");print RESET;
  #
  $cmd="$TH $LUA -force_cudnn 1 -gpu $GPU -model_dir $MODELDIR -m $OP -noise_level $NOISE -i $IIN -o $OOUT $LOG2";
  verbose($cmd);
  print("--------> waifu2x [op:$OP noise:$NOISE gpu:$GPU]\n");
  system $cmd;

if ($OUTSIZE || ($POSTOP ne ""))
  {
  if ($OUTSIZE) {$GMIC1="-resize2dy $OUTSIZE,5";} else {$GMIC1="";}
  if ($POSTOP ne "") {$GMIC2=$POSTOP;} else {$GMIC2="";}
  $cmd="$GMIC -i $OOUT $GMIC1 $GMIC2 -o $OOUT $LOG2";
  verbose($cmd);
  print("--------> resize/postop [size:$OUTSIZE postop:$POSTOP]\n");
  system $cmd;
  }
#-----------------------------#
($s2,$m2,$h2)=localtime(time);
($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
#print BOLD YELLOW "\nWriting $OOUT took $hlat:$mlat:$slat\n";print RESET;
#afanasy parsing format
print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
#-----------------------------#
 }
}
}#end csv

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
$CMD="WAIFU2X";
$FRAMESINC=1;
$PARSER="gpuserv";
$SERVICE="gpuserv";
$OFFLINE="true";

$WORKINGDIR=$CWD;
$BLOCKNAME="$OUT\_$SHOT";
$JOBNAME="$scriptname\_$OUT\_$SHOT";
    
if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT";
    $FILES="$OUTDIR/$SHOT/$OUT.\@####\@.$EXT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP";
    $FILES="$OUTDIR/$OUT.\@####\@.$EXT";
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
