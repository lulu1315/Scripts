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
$OUTDIR="$CWD/repaired";
$OUT="ima";
$OUT_USE_SHOT=0;
#preprocess
$DOLOCALCONTRAST=0;
$EQUALIZE=0;
$EQUALIZEMIN="20%";
$EQUALIZEMAX="80%";
$PREROLLING=0;
$POSTROLLING=0;
$BLUR=0;
$DOBILATERAL=0;
$BILATERALSPATIAL=5;
$BILATERALVALUE=5;
$BILATERALITER=1;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOBLACKANDWHITE=0;
#edges params
$SIZE=0;
$DOARCNN=0;
$ARCNNQUALITY=10;
$ZEROPAD=4;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
$CSV=0;
$CLEAN=1;
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
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(EQUALIZE);
print AUTOCONF confstr(EQUALIZEMIN);
print AUTOCONF confstr(EQUALIZEMAX);
print AUTOCONF confstr(PREROLLING);
print AUTOCONF confstr(DOBLACKANDWHITE);
print AUTOCONF "#arcnn\n";
print AUTOCONF confstr(DOARCNN);
print AUTOCONF confstr(ARCNNQUALITY);
print AUTOCONF "#postprocess\n";
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF confstr(POSTROLLING);
print AUTOCONF confstr(BLUR);
print AUTOCONF confstr(DOBILATERAL);
print AUTOCONF confstr(BILATERALSPATIAL);
print AUTOCONF confstr(BILATERALVALUE);
print AUTOCONF confstr(BILATERALITER);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(SIZE);
print AUTOCONF "#misc\n";
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
print AUTOCONF "1\n";
close AUTOCONF;
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
	print "-zeropad [4]\n";
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
    print "writing $scriptname\_auto.conf : mv $scriptname\_auto.conf $scriptname.conf\n";
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
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad : $ZEROPAD\n";
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
if ($userName eq "lulu" || $userName eq "dev" || $userName eq "dev18" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  $ARCNN="python3 /shared/foss-18/PyTorch-ARCNN/run.py";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}
$pid=$$;

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
    
for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
{
#
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
    $OOUT="$OOUTDIR/$OUT.$ii.$EXT";
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    }
else
    {
    $OOUTDIR="$OUTDIR";
    $OOUT="$OUTDIR/$OUT.$ii.$EXT";
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
  #workdir
  $WORKDIR="$OOUTDIR/w$ii\_$pid";
  if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
  #-----------------------------#
  ($s1,$m1,$h1)=localtime(time);
  #-----------------------------#
  $I=0;
  $PIN=$IIN;$I++;$POUT="$WORKDIR/$I.png";
  $initcmd="cp $PIN $POUT";
  verbose($initcmd);
  system $initcmd;
  #preprocess
    if ($PREROLLING) 
        {$GMIC1="-fx_sharp_abstract $PREROLLING,10,0.5,0,0";} else {$GMIC1="";}
    if ($EQUALIZE) 
        {$GMIC2="-equalize 256,$EQUALIZEMIN,$EQUALIZEMAX";} else {$GMIC2="";}
    if ($DOBLACKANDWHITE) 
        {$GMIC3="-to_colormode 1";} else {$GMIC3="-to_colormode 3";}
  $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
  $cmd="$GMIC -i $PIN $GMIC2 $GMIC1 $GMIC3 -to_colormode 3 -o $POUT $LOG2";
  verbose($cmd);
  print("--------> preprocess input [equalize:$EQUALIZE prerolling:$PREROLLING black/white [$DOBLACKANDWHITE]\n");
  system $cmd;
  #ARCNN
  if ($DOARCNN)
    {
    $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
    $cmd="$ARCNN --inputima $PIN $OP --outputima $POUT --quality $ARCNNQUALITY $LOG2";
    verbose($cmd);
    system $cmd;
    }
  #postprocess
    if ($DOLOCALCONTRAST) 
        {$GMIC1="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC1="";}
    if ($POSTROLLING) 
        {$GMIC2="-fx_sharp_abstract $POSTROLLING,10,0.5,0,0";} else {$GMIC2="";}
    if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
        {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} else {$GMIC3="";}
    if ($SIZE) 
        {$GMIC4="-resize2dx $SIZE,5";} else {$GMIC4="";}
    if ($BLUR) 
        {$GMIC5="-blur $BLUR";} else {$GMIC5="";}
    if ($DOBILATERAL) 
        {$GMIC6="-fx_smooth_bilateral $BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER,0,0";} else {$GMIC6="";}
  $PIN="$WORKDIR/$I.png";$I++;$POUT="$WORKDIR/$I.png";
  $cmd="$GMIC -i $PIN $GMIC4 $GMIC1 $GMIC2 $GMIC3 $GMIC6 $GMIC5 -o $POUT $LOG2";
  verbose($cmd);
  print("--------> postprocess input [size:$SIZE lce:$DOLOCALCONTRAST postrolling:$POSTROLLING blur:$BLUR bilateral:$DOBILATERAL,$BILATERALSPATIAL,$BILATERALVALUE,$BILATERALITER bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
  system $cmd;
  #final
  $finalcmd="cp $POUT $OOUT";
  verbose($finalcmd);
  system $finalcmd;
  #-----------------------------#
  ($s2,$m2,$h2)=localtime(time);
  ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
  #print BOLD YELLOW "gmic : frame $ii took $hlat:$mlat:$slat \n\n";print RESET;
  #-----------------------------#
  #afanasy parsing format
  print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat\n";print RESET;
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
