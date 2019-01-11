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
$SKETCHDIR="$CWD/edges";
$SKETCH="ima";
$IN_USE_SHOT=0;
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$HINTDIR="$CWD/slic";
$HINT="ima_hint";
$OUTDIR="$CWD/mangastyle";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
#preprocess
$INVERTSKETCH=1;
$GAIN=0;
$DREAMSMOOTH=0;
$DILATE=0;
$HINTDILATE=10;
$HINTGAIN=0;
#manga params
$SIZE=0;
$VERSION=4;
$DENOISE=0;
$CLEAN=1;
$CSV=0;
$PARAMS="_v\$VERSION";
#gpu id
$GPU=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
#JSON
$CAPACITY=1000;
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
open (AUTOCONF,">","mangastyle_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(SKETCHDIR);
print AUTOCONF confstr(SKETCH);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(HINTDIR);
print AUTOCONF confstr(HINT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(INVERTSKETCH);
print AUTOCONF confstr(GAIN);
print AUTOCONF confstr(DREAMSMOOTH);
print AUTOCONF confstr(DILATE);
print AUTOCONF confstr(HINTDILATE);
print AUTOCONF confstr(HINTGAIN);
print AUTOCONF "#manga parameters\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(VERSION);
print AUTOCONF "#version = 0 : all versions\n";
print AUTOCONF confstr(DENOISE);
print AUTOCONF confstr(PARAMS);
print AUTOCONF "#\n";
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CSV);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
print AUTOCONF "1\n";
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-autoconf\n";
	print "-conf file.conf\n";
	print "-f startframe endframe\n";
	print "-force [0]\n";
	print "-verbose\n";
    print "-gpu gpu_id [0]\n";
    print "-shot shotname\n";
    print "-style stylename\n";
	print "-csv csv_file.csv\n";
	print "-json [submit to afanasy]\n";
	print "-open/close (set python env on/off]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing mangastyle_auto.conf : mv mangastyle_auto.conf mangastyle.conf \n";
    autoconf();
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
 if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shotname : $SHOT\n";
    }
 if (@ARGV[$arg] eq "-style") 
    {
    $STYLE=@ARGV[$arg+1];
    print "style : $STYLE\n";
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
  if (@ARGV[$arg] eq "-open") 
    {
    $cmd="echo \"mangastyle\" > ~/.pyenv/version";
    print "$cmd\n";
    system $cmd;
    exit;
    }
  if (@ARGV[$arg] eq "-close") 
    {
    $cmd="echo \"\" > ~/.pyenv/version";
    print "$cmd\n";
    system $cmd;
    exit;
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
            $STYLE=@line[1];
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
  $MANGA="python /shared/foss/style2paints/server/mangastyle.py";
  $cmd="echo \"mangastyle\" > ~/.pyenv/version";
  print "$cmd\n";
  system $cmd;
  }
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $MANGA="python3 /shared/foss-18/style2paints/mangastyle.py";
  }

if ($userName eq "lulu")	#
  {
  $GMIC="/usr/bin/gmic";
  $MANGA="python /mnt/shared/v16/style2paints/server/mangastyle.py";
  $cmd="echo \"mangastyle\" > ~/.pyenv/version";
  print "$cmd\n";
  system $cmd;
  }

sub manga {
#auto frames
if ($FSTART eq "auto" || $FEND eq "auto")
    {
    $AUTODIR="$SKETCHDIR/$SHOT";
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
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    }
    
#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
@tmp=split(/\./,$SKETCH);
$SSKETCH=@tmp[0];

for ($i=$FSTART ; $i <= $FEND ; $i++)
{
$ii=sprintf("%04d",$i);

#output
if ($IN_USE_SHOT)
    {
    $SSSKETCH="$SKETCHDIR/$SHOT/$SKETCH.$ii.$EXT";
    }
else
    {
    $SSSKETCH="$SKETCHDIR/$SKETCH.$ii.$EXT";
    }
    
if ($VERSION) {$FINALFRAME="$OOUTDIR/$SSKETCH\_$SSTYLE$PARAMS.$ii.$EXT";}
else {$FINALFRAME="$OOUTDIR/$SSKETCH\_$SSTYLE\_montage.$ii.$EXT";}

if (-e $FINALFRAME && !$FORCE)
   {print BOLD RED "frame $FINALFRAME exists ... skipping\n";print RESET;}
else
  {
  $touchcmd="touch $FINALFRAME";
  verbose($touchcmd);
  system $touchcmd;
  #
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  print BOLD YELLOW "\nframe : $ii -> $FINALFRAME\n";print RESET;
  #
  $WORKDIR="$OOUTDIR/w$ii";
  if (!-e "$WORKDIR") {$cmd="mkdir $WORKDIR";system $cmd;}
  #preprocess style
  $cmd="$GMIC $STYLEDIR/$STYLE -to_colormode 4 -o $WORKDIR/$SSTYLE.png $LOG2";
  verbose($cmd);
  print("--------> preprocess style\n");
  system $cmd;
  #preprocess content
  if ($SIZE) {$GMIC1="-resize2dx $SIZE,1";} else {$GMIC1="";}
  if ($DREAMSMOOTH) {$GMIC2="-fx_dreamsmooth 10,0,1,0.8,0,0.8,0,24,0";} else {$GMIC2="";}
  verbose ($DILATE);
  if ($DILATE && $INVERTSKETCH) {$GMIC3="-dilate $DILATE";}# else {$GMIC3="";}
  if ($DILATE && !$INVERTSKETCH) {$GMIC3="-erode_circ $DILATE";}# else {$GMIC3="";}
  if ($GAIN) 
        {$GMIC4="-fx_adjust_colors $GAIN,0,0,0,0";} else {$GMIC4="";}
  if ($INVERTSKETCH) 
        {$GMIC5="-n 0,1 -oneminus -n 0,255";} else {$GMIC5="";}
  $cmd="$GMIC $SSSKETCH -to_colormode 3 $GMIC1 $GMIC4 $GMIC3 $GMIC2 $GMIC5 -to_colormode 4 -o $WORKDIR/$SSKETCH.png $LOG2";
  $GMIC3="";
  verbose($cmd);
  print("--------> preprocess sketch [size:$SIZE invert:$INVERTSKETCH gain:$GAIN dilate:$DILATE smooth:$DREAMSMOOTH]\n");
  system $cmd;
  #
  $REFERENCE="$WORKDIR/$SSTYLE.png";
  $INVSKETCH="$WORKDIR/$SSKETCH.png";
  #preprocess hint
  $HINTFRAME="$HINTDIR/$HINT.$ii.png";
  if ($HINT eq "")
    {
    $cmd="$GMIC $SSSKETCH -to_colormode 4 -mul 0 -o $WORKDIR/hint.png $LOG2";
    verbose($cmd);
    print("--------> preprocess black hint\n");
    system $cmd;
    $HINTFRAME="$WORKDIR/hint.png";
    }
  if ($SIZE) {$GMIC1="-resize2dx $SIZE,1";} else {$GMIC1="";}
  if ($HINTDILATE) {$GMIC2="-dilate_circ $HINTDILATE";} else {$GMIC2="";}
  if ($HINTGAIN) {$GMIC3="-fx_adjust_colors $HINTGAIN,0,0,0,0";} else {$GMIC3="";}
  $cmd="$GMIC $HINTFRAME $GMIC2 $GMIC3 $GMIC1 -o $WORKDIR/hint.png $LOG2";
  verbose($cmd);
  print("--------> preprocess hint [size:$SIZE dilate:$HINTDILATE gain:$HINTGAIN]\n");
  system $cmd;
  $HINTFRAME="$WORKDIR/hint.png";
  #must be in a python 3.6 env
  if ($VERSION)
    {
    $mangacmd="$MANGA $GPU $INVSKETCH $REFERENCE $HINTFRAME $VERSION $DENOISE $FINALFRAME $LOG2";
    verbose($mangacmd);
    print("--------> manga transfert [gpu:$GPU version:$VERSION denoise:$DENOISE]\n");
    system $mangacmd;
    }
  else
    {
    for ($VVERSION=1 ; $VVERSION <= 4 ; $VVERSION++)
        {
        $FINALFRAME="$OOUTDIR/$SSKETCH\_$SSTYLE\_v$VVERSION.$ii.$EXT";
        $mangacmd="$MANGA $GPU $INVSKETCH $REFERENCE $HINTFRAME $VVERSION $DENOISE $FINALFRAME $LOG2";
        verbose($mangacmd);
        print("--------> manga transfert [gpu:$GPU version:$VVERSION denoise:$DENOISE]\n");
        system $mangacmd;
        }
    $M1="$OOUTDIR/$SSKETCH\_$SSTYLE\_v1.$ii.$EXT";
    $M2="$OOUTDIR/$SSKETCH\_$SSTYLE\_v2.$ii.$EXT";
    $M3="$OOUTDIR/$SSKETCH\_$SSTYLE\_v3.$ii.$EXT";
    $M4="$OOUTDIR/$SSKETCH\_$SSTYLE\_v4.$ii.$EXT";
    #$cmd="$GMIC $M1 $M2 $M3 $M4 -text_outline[0] \"1\" -text_outline[1] \"2\" -text_outline[2] \"3\" -text_outline[3] \"4\" -montage X -o $OOUTDIR/$SSKETCH\_$SSTYLE\_montage.$ii.$EXT $LOG2";
    $cmd="$GMIC $M1 $M2 $M3 $M4 -montage X -o $OOUTDIR/$SSKETCH\_$SSTYLE\_montage.$ii.$EXT $LOG2";
    verbose($cmd);
    print("--------> montage\n");
    system $cmd;
    }
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #print BOLD YELLOW "frame : $ii - MANGASTYLE took $hlat:$mlat:$slat \n";print RESET;
  #afanasy parsing format
  print BOLD YELLOW "Writing $FINALFRAME took $hlat:$mlat:$slat\n";print RESET;
  #-----------------------------#
  if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
  }
}
}#swap sub

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
    $VERSION=@line[2];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $suffix=@line[7];
    if ($process)
      {
      manga();
      }
    }
   }
else
  {
  manga();
  }

#$cmd="echo \"\" > ~/.pyenv/version";
#print "$cmd\n";
#system $cmd;
  
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
$CMD="MANGA";
$FRAMESINC=1;
$PARSER="gpuserv";
$SERVICE="gpuserv";
$OFFLINE="true";

$WORKINGDIR=$CWD;
$BLOCKNAME="$SHOT";
$JOBNAME="$scriptname\_$SHOT";
    
#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
@tmp=split(/\./,$SKETCH);
$SSKETCH=@tmp[0];

if ($VERSION) 
    {
    $OUT="$SSKETCH\_$SSTYLE$PARAMS.\@####\@.$EXT";
    }
else 
    {
    $OUT="$SSKETCH\_$SSTYLE\_montage.\@####\@.$EXT";
    }

if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT -style $STYLE";
    $FILES="$OUTDIR/$SHOT/$OUT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -style $STYLE";
    $FILES="$OUTDIR/$OUT";
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
