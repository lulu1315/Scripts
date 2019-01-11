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
$INDIR="$CWD/originales";
$IN="ima";
$IN_USE_SHOT=0;
$SHOT="";
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$OUTDIR="$CWD/ideep";
$OUT="ima";
$OUT_USE_SHOT=0;
$ZEROPAD=1;
$FORCE=0;
$EXTIN="png";
$EXTOUT="png";
#preprocess
$SIZE=0;
$DOLOCALCONTRAST=0;
$ROLLING=2;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
#misc
$CSV=0;
$VERBOSE=0;
$CLEAN=1;
#JSON
$CAPACITY=1000;
$SKIP="-force";
$FPT=5;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";

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
open (AUTOCONF,">","ideep_auto.conf");
print AUTOCONF confstr(PROJECT);
print AUTOCONF confstr(FSTART);
print AUTOCONF confstr(FEND);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(INDIR);
print AUTOCONF confstr(IN);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(OUT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(CSV);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF "1\n";
}

if ($#ARGV == -1) {
  print "usage: $scriptname \n";
      print "-f startframe endframe\n";
      print "-idir dirin\n";
      print "-i imagein\n";
      print "-odir dirout\n";
      print "-o imageout\n";
      print "-e image ext (png)\n";
      print "-zeropad4\n";
      print "-force\n";
      print "-csv csv_file.csv\n";
      print "-json [submit to afanasy]\n";
      exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf")
    {
    print "writing ideep_auto.conf : mv ideep_auto.conf ideep.conf\n";
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
    print "shot : $SHOT\n";
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
    print "verbose ...\n";
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
  $IDEEPCOLOR="/usr/bin/python /shared/foss/interactive-deep-colorization/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/interactive-deep-colorization/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/interactive-deep-colorization/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/interactive-deep-colorization/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/interactive-deep-colorization/models/global_model/dummy.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss/caffe-1604/python:/shared/foss/interactive-deep-colorization/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss/caffe-1604/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($userName eq "lulu")	#
  {
  $GMIC="/usr/bin/gmic";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss/caffe-cpu/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
sub csv {
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
#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
@tmp=split(/\./,$IN);
$INSHORT=@tmp[0];

for ($i = $FSTART ;$i <= $FEND;$i++)
{
$ii=sprintf("%04d",$i);
#preprocess
if ($IN_USE_SHOT)
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXTIN";
    }

if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR=$OUTDIR;
    }
    
$OOUT="$OOUTDIR/$INSHORT\_$SSTYLE.$ii.$EXTOUT";

if (-e $OOUT && !$FORCE)
{print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else
  {
  #touch file
  $touchcmd="touch $OOUT";
  verbose($touchcmd);
  system $touchcmd;
  verbose("processing frame $ii");
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  #workdir
  $WORKDIR="$OOUTDIR/w$ii";
  if (!-e "$WORKDIR") {$cmd="mkdir $WORKDIR";system $cmd;}
  #preprocess
  $I=1;
  if ($EXTIN eq "exr") 
        {$GMIC0="-apply_gamma 2.2 -n 0,255";} else {$GMIC0="";}
  if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC1="";}
    if ($ROLLING) 
        {$GMIC2="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC2="";}
    if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";}  else {$GMIC4="";}
  $cmd="$GMIC -i $IIN $GMIC0 $GMIC4 $GMIC1 $GMIC2 $GMIC3 -o $WORKDIR/$I.png $LOG2";
  verbose($cmd);
  print("--------> preprocess input [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  $IIN="$WORKDIR/$I.png";
  #
  $cmd="$IDEEPCOLOR $IIN $STYLEDIR/$STYLE $OOUT $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL $LOG2";
  verbose($cmd);
  print("--------> ideepcolor\n");
  system $cmd;
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #afanasy parsing format
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
  #-----------------------------#
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
    $STYLE=@line[1];
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
sub hmstoglob {
my ($s,$m,$h) = @_;
my $glob;
#
$glob=$s+60*$m+3600*$h;
return $glob;
}
sub globtohms {
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
#     print "$glob1 $glob2 $glob \n";
      my ($s,$m,$h) =globtohms($glob);
      return ($s,$m,$h);
}

sub json {
$CMD="COLOR_ideep";
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
@tmp=split(/\./,$IN);
$INSHORT=@tmp[0];

if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR=$OUTDIR;
    }
    
$OOUT="$OOUTDIR/$INSHORT\_$SSTYLE.\@####\@.$EXTOUT";

if ($OUT_USE_SHOT)
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -shot $SHOT -style $STYLE";
    $FILES="$OOUT";
    }
else
    {
    $COMMAND="$CMD.pl -conf $CONF -f @#@ @#@ $SKIP -style $STYLE";
    $FILES="$OOUT";
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

