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
$INDIR="$CWD/strotss";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/storyboard";
$OUT="ima";
$OUT_USE_SHOT=0;
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$SIZEX=1920;
$SIZEY=1080;
$SIZEXIN=1280;
$SIZEYIN=960;
$SIZESTYLE=640;
$INTERVAL=40;
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CSV=0;
$LOG1=">/var/tmp/$scriptname.log";
$LOG2="2>/var/tmp/$scriptname.log";
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
open (AUTOCONF,">","$scriptname\_auto.conf");
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
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF "#sizes\n";
print AUTOCONF confstr(SIZEX);
print AUTOCONF confstr(SIZEY);
print AUTOCONF confstr(SIZEXIN);
print AUTOCONF confstr(SIZEYIN);
print AUTOCONF confstr(SIZESTYLE);
print AUTOCONF confstr(INTERVAL);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
#print AUTOCONF confstr(OFFLINE);
print AUTOCONF "1\n";
close AUTOCONF;
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

if ($VERBOSE) {$LOG1="";$LOG2="";}

if ($userName eq "dev18")	#
  {
  $GMIC="/usr/bin/gmic";
  }

sub storyboard {
#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
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
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
        if ($ZEROPAD == 4) {$ii=sprintf("%04d",$i);}
        if ($ZEROPAD == 5) {$ii=sprintf("%05d",$i);}
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
            $OOUT="$OOUTDIR/$OUT\_$SSTYLE.$ii.$EXT";
            if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
            else {$cmd="mkdir $OOUTDIR";system $cmd;}
            }
        else
            {
            $OOUTDIR="$OUTDIR";
            $OOUT="$OUTDIR/$OUT\_$SSTYLE.$ii.$EXT";
            if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
            else {$cmd="mkdir $OOUTDIR";system $cmd;}
            }
    if (-e $OOUT && !$FORCE)
        {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
    else {
        #touch file
        $touchcmd="touch $OOUT";
        if ($VERBOSE) {print "$touchcmd\n";}
        #verbose($touchcmd);
        system $touchcmd;
        $VAL1=$SIZEXIN+2*$INTERVAL;
        $VAL2=$SIZESTYLE+2*$INTERVAL;
        $cmd="$GMIC -i $IIN -i $STYLEDIR/$STYLE -resize[0] $VAL1,$SIZEYIN,1,3,0,0,.5,.5 -resize2dx[1] $SIZESTYLE,5 -resize[1] $SIZESTYLE,$SIZEYIN,1,3,0,0,.5,.5 -resize[1] $VAL2,$SIZEYIN,1,3,0,0,.5,.5 -montage H -resize2dx $SIZEX,5  -resize $SIZEX,$SIZEY,1,3,0,0,.5,.5 -c 0,255 -o $OOUT $LOG2";
        verbose($cmd);
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        system $cmd;
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        #-----------------------------#
        #afanasy parsing format
        print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
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
    $IN=@line[1];
    $STYLE=@line[2].".jpg";
    $FSTART=@line[3];
    $FEND=@line[4];
    $process=@line[5];
    if ($process)
      {
      storyboard();
      }
    }
   }
else
  {
  storyboard();
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
