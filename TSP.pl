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
$CONTINUE=-1;
$SHOT="";
$INDIR="$CWD/stippling";
$IN="ima";
$IN_USE_SHOT=0;
$OUTDIR="$CWD/tsp";
$OUT="ima";
$OUT_USE_SHOT=0;
$LINKERNITER=3;
$RANDOMSEED=33;
$CSVFILE="./SHOTLIST.csv";
$ZEROPAD=4;
$FORCE=0;
$EXT="ply";
$VERBOSE=0;
$CLEAN=1;
$CSV=0;
$SOLVER="linkern";
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
print AUTOCONF confstr(SOLVER);
print AUTOCONF "#linkern (fast) or concorde (slow)\n";
print AUTOCONF confstr(LINKERNITER);
print AUTOCONF confstr(RANDOMSEED);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(CLEAN);
print AUTOCONF "#json - submit to afanasy\n";
print AUTOCONF confstr(CAPACITY);
print AUTOCONF confstr(SKIP);
print AUTOCONF confstr(FPT);
#print AUTOCONF confstr(OFFLINE);
print AUTOCONF confstr(PARAMS);
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
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad : $ZEROPAD\n";
    }
  if (@ARGV[$arg] eq "-shot") 
    {
    $SHOT=@ARGV[$arg+1];
    print "shot $SHOT\n";
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
  }
  
$userName =  $ENV{'USER'}; 
  
if ($userName eq "dev18")	#
  {
  $CONCORDE="/shared/foss-18/pyconcorde/build/concorde/TSP/concorde";
  $LINKERN="/shared/foss-18/pyconcorde/build/concorde/LINKERN/linkern";
  }
  
sub tsp {

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
    
$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

$pid=$$;
      
for ($i=$FSTART ; $i <= $FEND ; $i=$i+$FSTEP)
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
    {
    $IIN="$INDIR/$SHOT/$IN.$ii.$EXT";
    $JJN="$INDIR/$SHOT/$IN.$jj.$EXT";
    }
else
    {
    $IIN="$INDIR/$IN.$ii.$EXT";
    $JJN="$INDIR/$IN.$jj.$EXT";
    }
    
if ($OUT_USE_SHOT)
    {
    $OOUTDIR="$OUTDIR/$SHOT";
    $OOUT="$OOUTDIR/$OUT$PARAMS.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    $OOUT="$OUTDIR/$OUT$PARAMS.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
    
#working dir
$WORKDIR="$OOUTDIR/w$ii\_$pid";

if (-e $OOUT && !$FORCE)
   {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
else {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
    #touch file
    $touchcmd="touch $OOUT";
    if ($VERBOSE) {print "$touchcmd\n";}
    #verbose($touchcmd);
    system $touchcmd;
    print BOLD BLUE ("\nframe : $ii\n");print RESET;
    if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
    $VERTEX=0;
    #convert ply to tsp#
    $TSPFILE="$WORKDIR/input.tsp";
    #copy ply to workdir
    $cpcmd="cp $IIN $WORKDIR";
    verbose($cpcmd);
    system($cpcmd);
    #parse ply
    open (PLY , "$IIN");
    while ($line=<PLY>)
    {
    chop $line;
    @line=split(/ /,$line);
    if (@line[0] eq "element" && @line[1] eq "vertex")
        {
        print ("@line[1] @line[2]\n");
        $VERTEX=@line[2];
        }
    if (@line[0] eq "end_header")
        {
        print ("@line[0]\n");
        last;
        }
    }
    open (TSP ,'>', $TSPFILE);
    print TSP "NAME: mytsp\n";
    print TSP "TYPE: TSP\n";
    print TSP "COMMENT: $OOUT\n";
    print TSP "DIMENSION: $VERTEX\n";
    print TSP "EDGE_WEIGHT_TYPE: EUC_2D\n";
    print TSP "NODE_COORD_SECTION\n";
    for ($v=1 ; $v <= $VERTEX ; $v++)
        {
        $line=<PLY>;
        chop $line;
        @line=split(/ /,$line);
        $tspx=@line[0]*1024;
        $tspy=@line[2]*1024;
        print TSP "$v $tspx $tspy\n";
        #print ("vertex $v : @line[0] @line[1] @line[2] @line[3]\n");
        }
    print TSP "EOF\n";
    close TSP;
    close PLY;
    if ($SOLVER eq "concorde")
        {
        #do concorde
        $concordecmd="$CONCORDE -x -o $WORKDIR/output.sol $TSPFILE";
        verbose($concordecmd);
        system $concordecmd;
        #generate final ply
        open (FINAL ,'>', "$WORKDIR/final.ply");
        open (PLY , $IIN);
        while ($line=<PLY>)
            {
            chop $line;
            @line=split(/ /,$line);
            if (@line[0] eq "element" && @line[1] eq "face")
                {
                print FINAL ("element face 1\n");
                }
            else 
                {
                print FINAL ("$line\n");
                }
            }
        open (SOL , "$WORKDIR/output.sol");
        $line=<SOL>;
        chop $line;
        print FINAL "$line ";
        while ($line=<SOL>)
            {
            chop $line;
            print FINAL "$line";
            }
        print FINAL "\n";
        close SOL;
        close FINAL;
        }
    if ($SOLVER eq "linkern")
        {
        #do linkern
        $linkerncmd="cd $WORKDIR;$LINKERN -s $RANDOMSEED -r $LINKERNITER -o $WORKDIR/output.sol $TSPFILE";
        verbose($linkerncmd);
        system $linkerncmd;
        #generate final ply
        open (FINAL ,'>', "$WORKDIR/final.ply");
        open (PLY , $IIN);
        while ($line=<PLY>)
            {
            chop $line;
            @line=split(/ /,$line);
            if (@line[0] eq "element" && @line[1] eq "face")
                {
                print FINAL ("element face 1\n");
                }
            else 
                {
                print FINAL ("$line\n");
                }
            }
        open (SOL , "$WORKDIR/output.sol");
        while ($line=<SOL>)
            {
            chop $line;
            @line=split(/ /,$line);
            print FINAL ("@line[0] ");
            }
        print FINAL "\n";
        close SOL;
        close FINAL;
        }
    #cp final.ply
    $cpcmd="cp $WORKDIR/final.ply $OOUT";
    verbose($cpcmd);
    system $cpcmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    print BOLD YELLOW "\nWriting  STIPPLING $ii took $hlat:$mlat:$slat \n";print RESET;
    #-----------------------------#
    if ($CLEAN)
        {
        $cleancmd="rm -r $WORKDIR";
        verbose($cleancmd);
        system $cleancmd;
        }
    }#end do
  }#end for
}#end tsp

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
      tsp();
      }
    }
   }
else
  {
  tsp();
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
