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
$OUTDIR="$CWD/openface";
$OUT="ima";
$OUT_USE_SHOT=0;
$METHOD=0;
$DLIBMETHOD=1;
$FACEALIGNTYPE="3D-full";
$FACEALIGNMODEL="3D-FAN";
$EOSMARKDIR="$CWD/openface/\$SHOT/dlib";
$EOSMARK="ima_crop_dnn";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$EXTIN="\$EXT";
$EXTOUT="\$EXT";
$VERBOSE=0;
$CSV=0;
$LOG1=">/var/tmp/openface.log";
$LOG2="2>/var/tmp/openface.log";


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
open (AUTOCONF,">","openface_auto.conf");
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
print AUTOCONF confstr(METHOD);
print AUTOCONF "#method 0 : Openface FLI (images)\n";
print AUTOCONF "#method 1 : Openface FEA (sequence)\n";
print AUTOCONF "#method 2 : DLIB detector\n";
print AUTOCONF confstr(DLIBMETHOD);
print AUTOCONF "#0:hog detector , 1:dnn detector\n";
print AUTOCONF "#method 3 : PRNet\n";
print AUTOCONF "#method 4 : FACEALIGN\n";
print AUTOCONF confstr(FACEALIGNTYPE);
print AUTOCONF "#2D,3D,3D-full\n";
print AUTOCONF confstr(FACEALIGNMODEL);
print AUTOCONF "#2D-FAN-300W\n";
print AUTOCONF "#2D-FAN-generic\n";
print AUTOCONF "#3D-FAN\n";
print AUTOCONF "#method 5 : Expression-Net\n";
print AUTOCONF "#method 6 : EOS\n";
print AUTOCONF confstr(EOSMARKDIR);
print AUTOCONF confstr(EOSMARK);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF confstr(EXTIN);
print AUTOCONF confstr(EXTOUT);
print AUTOCONF "1\n";
close AUTOCONF;
}

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
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
    print "writing openface_auto.conf : mv openface_auto.conf openface.conf\n";
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
  if (@ARGV[$arg] eq "method") 
    {
    $METHOD=@ARGV[$arg+1];
    print "method: $METHOD\n";
    }
  if (@ARGV[$arg] eq "-dlibmethod") 
    {
    $DLIBMETHOD=@ARGV[$arg+1];
    print "dlib method: $DLIBMETHOD\n";
    }
  if (@ARGV[$arg] eq "-facealigntype") 
    {
    $FACEALIGNTYPE=@ARGV[$arg+1];
    print "facealign type: $FACEALIGNTYPE\n";
    }
  if (@ARGV[$arg] eq "-facealignmodel") 
    {
    $FACEALIGNMODEL=@ARGV[$arg+1];
    print "facealign model: $FACEALIGNMODEL\n";
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
  $FLI="/shared/foss/OpenFace/build/bin/FaceLandmarkImg";
  $FEA="/shared/foss/OpenFace/build/bin/FeatureExtraction";
  $DLIB="/shared/foss/dlib-19.16/lulu_examples/build/lulu_dlib_landmarks";
  #$DLIBHOG="/shared/foss/dlib-19.16/lulu_examples/build/face_landmark_detection_ex";
  #$DLIBDNN="/shared/foss/dlib-19.16/lulu_examples/build/dnn_mmod_face_detection_ex";
  $DLIBPREDICTOR="/shared/foss/dlib-19.16/lulu_examples/shape_predictor_68_face_landmarks.dat";
  $DLIBDETECTOR="/shared/foss/dlib-19.16/lulu_examples/mmod_human_face_detector.dat";
  $PRNet="python /shared/foss/PRNet/PRNet_lulu.py";
  $FACEALIGN="th /shared/foss/2D-and-3D-face-alignment/lulu_main.lua";
  $FACEMODELPATH="/shared/foss/2D-and-3D-face-alignment/models";
  #$FACEMODEL="/shared/foss/2D-and-3D-face-alignment/models/2D-FAN-generic.t7";
  #$FACEMODEL="/shared/foss/2D-and-3D-face-alignment/models/3D-FAN.t7";
  $FACEMODELZ="/shared/foss/2D-and-3D-face-alignment/models/3D-FAN-depth.t7";
  #$FACEMODELZ="/shared/foss/2D-and-3D-face-alignment/models/2D-to-3D-FAN.t7";
  $EXPRNet="python /shared/foss/Expression-Net/lulu_ExpNet.py";
  $EOS="/shared/foss/eos_install/bin/fit-model";
  $EOSMODEL="/shared/foss/eos_install/share/sfm_shape_3448.bin";
  $EOSMAPPING="/shared/foss/eos_install/share/ibug_to_sfm.txt";
  $EOSCONTOUR="/shared/foss/eos_install/share/sfm_model_contours.json";
  $EOSEDGE="/shared/foss/eos_install/share/sfm_3448_edge_topology.json";
  $EOSBLEND="/shared/foss/eos_install/share/expression_blendshapes_3448.bin";
  }
  
if ($VERBOSE) {$LOG1="";$LOG2="";}

sub csv {
    
if ($METHOD == 0)
{
    if ($IN_USE_SHOT)
        {
        $IIN="$INDIR/$SHOT/$IN.\%04d.$EXTIN";
        }
    else
        {
        $IIN="$INDIR/$IN.\%04d.$EXTIN";
        }
    
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $PLYDIR="$OOUTDIR/openface_video";
    if (-e "$PLYDIR") {print "$PLYDIR already exists\n";}
    else {$cmd="mkdir $PLYDIR";system $cmd;}
    
    $cmd="$FEA -f $IIN -out_dir $PLYDIR -of $OUT -verbose -wild -multi_view 1";
    #$cmd="$FEA -f $IIN -out_dir $OOUTDIR -of $OUT -verbose";
    verbose($cmd);
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
    system $cmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "OpenFace took $hlat:$mlat:$slat\n";print RESET;

    $LANDMARK="$PLYDIR/$OUT.csv";
    open (LANDMARK , "$LANDMARK");
    $count=0;
    $line=<LANDMARK>;
    while ($line=<LANDMARK>)
        {
        #ply
        chop $line;
        @line=split(/,/,$line);
        $frame=@line[0];
        $timestamp=@line[2];
        $confidence=@line[3];
        $success=@line[4];
        #print ("$frame $timestamp $confidence $success\n");
        $count++;
        $ccount=sprintf("%04d",$count);
        $PLY2DOUT="$PLYDIR/$OUT\_2d.$ccount.ply";
        #print "writing $PLY2DOUT\n";
        print ".";
        open (PLY2D,">","$PLY2DOUT");
        print PLY2D "ply\n";
        print PLY2D "format ascii 1.0\n";
        print PLY2D "comment created by lulu the master of everything.\n";
        print PLY2D "element vertex 68\n";
        print PLY2D "property float x\n";
        print PLY2D "Hogproperty float y\n";
        print PLY2D "property float z\n";
        print PLY2D "property float success\n";
        print PLY2D "property float confidence\n";
        print PLY2D "element face 0\n";
        print PLY2D "property list uchar int vertex_indices\n";
        print PLY2D "end_header\n";
        for ($p = 1 ;$p <= 68;$p++)
            {
            print PLY2D "@line[$p+298] @line[$p+366] 0 $success $confidence\n";
            }
        close PLY2D;
    
        $PLY3DOUT="$PLYDIR/$OUT\_3d.$ccount.ply";
        #print "writing $PLY3DOUT\n";
        open (PLY3D,">","$PLY3DOUT");
        print PLY3D "ply\n";
        print PLY3D "format ascii 1.0\n";
        print PLY3D "comment created by lulu the master of everything.\n";
        print PLY3D "element vertex 68\n";
        print PLY3D "property float x\n";
        print PLY3D "property float y\n";
        print PLY3D "property float z\n";
        print PLY3D "property float success\n";
        print PLY3D "property float confidence\n";
        print PLY3D "element face 0\n";
        print PLY3D "property list uchar int vertex_indices\n";
        print PLY3D "end_header\n";
        for ($p = 1 ;$p <= 68;$p++)
            {
        print PLY3D "@line[$p+434] @line[$p+502] @line[$p+570] $success $confidence\n";
            }
        close PLY3D;
        close LANDMARK;
    }
    print "\n";
}

if ($METHOD == 1)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $WORKDIR="$OOUTDIR/work_$$";
    if (-e "$WORKDIR") {verbose("$WORKDIR already exists");}
    else {$cmd="mkdir $WORKDIR";system $cmd;}
    $PLYDIR="$OOUTDIR/openface";
    if (-e "$PLYDIR") {print "$PLYDIR already exists\n";}
    else {$cmd="mkdir $PLYDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
    $cmd="$FLI -f $IIN -out_dir $WORKDIR -of $OUT";
    verbose($cmd);
    system $cmd;
    #keep verbose
    $cmd="cp $WORKDIR/$OUT.jpg $PLYDIR/$OUT.$ii.jpg";
    verbose($cmd);
    system $cmd;
    
    $LANDMARK="$WORKDIR/$OUT.csv";
    open (LANDMARK , "$LANDMARK");
    $line=<LANDMARK>;
    $line=<LANDMARK>;
    chop $line;
    @line=split(/,/,$line);
    #$frame=@line[0];
    #$timestamp=@line[2];
    $confidence=@line[1];
    $success=1;
    #print ("$frame $timestamp $confidence $success\n");
    $PLY2DOUT="$PLYDIR/$OUT\_2d.$ii.ply";
    print "writing $PLY2DOUT\n";
    #print ".";
    open (PLY2D,">","$PLY2DOUT");
    print PLY2D "ply\n";
    print PLY2D "format ascii 1.0\n";
    print PLY2D "comment created by lulu the master of everything.\n";
    print PLY2D "element vertex 68\n";
    print PLY2D "property float x\n";
    print PLY2D "property float y\n";
    print PLY2D "property float z\n";
    print PLY2D "property float success\n";
    print PLY2D "property float confidence\n";
    print PLY2D "element face 0\n";
    print PLY2D "property list uchar int vertex_indices\n";
    print PLY2D "end_header\n";
    for ($p = 1 ;$p <= 68;$p++)
        {
        print PLY2D "@line[$p+295] @line[$p+363] 0 $success $confidence\n";
        #print PLY2D "@line[$p+298] @line[$p+366] 0 $success $confidence\n";
        }
    close PLY2D;
    
    $PLY3DOUT="$PLYDIR/$OUT\_3d.$ii.ply";
    print "writing $PLY3DOUT\n";
    open (PLY3D,">","$PLY3DOUT");
    print PLY3D "ply\n";
    print PLY3D "format ascii 1.0\n";
    print PLY3D "comment created by lulu the master of everything.\n";
    print PLY3D "element vertex 68\n";
    print PLY3D "property float x\n";
    print PLY3D "property float y\n";
    print PLY3D "property float z\n";
    print PLY3D "property float success\n";
    print PLY3D "property float confidence\n";
    print PLY3D "element face 0\n";
    print PLY3D "property list uchar int vertex_indices\n";
    print PLY3D "end_header\n";
    for ($p = 1 ;$p <= 68;$p++)
        {
        print PLY3D "@line[$p+431] @line[$p+499] @line[$p+567] $success $confidence\n";
        }
    close PLY3D;
    close LANDMARK;
    #
    $cmd="cp $WORKDIR/$OUT.csv $PLYDIR/$OUT.$ii.csv";
    verbose($cmd);
    system $cmd;
    $cmd="cp $WORKDIR/$OUT\_of_details.txt $PLYDIR/$OUT\_of_details.$ii.txt";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanas2y parsing format
    print BOLD YELLOW "OpenFace FLI image $ii took $hlat:$mlat:$slat\n";print RESET;
    }
$cmd="rm -rf $WORKDIR";
#$cmd="ls -al $WORKDIR";
verbose($cmd);
system $cmd;
}

if ($METHOD == 2)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $PLYDIR="$OOUTDIR/dlib";
    if (-e "$PLYDIR") {print "$PLYDIR already exists\n";}
    else {$cmd="mkdir $PLYDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
        
    if ($DLIBMETHOD == 0) {$DLIBFLAG="hog";}
    if ($DLIBMETHOD == 1) {$DLIBFLAG="dnn";}
    $cmd="$DLIB $DLIBDETECTOR $DLIBPREDICTOR $IIN $PLYDIR/$OUT\_$DLIBFLAG.$ii.jpg $PLYDIR/$OUT\_$DLIBFLAG.$ii.txt $DLIBMETHOD";
    verbose($cmd);
    system $cmd;
    
    $LANDMARK="$PLYDIR/$OUT\_$DLIBFLAG.$ii.txt";
    open (LANDMARK , "$LANDMARK");
    
    $PLY2DOUT="$PLYDIR/$OUT\_$DLIBFLAG.$ii.ply";
    print "writing $PLY2DOUT\n";
    open (PLY3D,">","$PLY2DOUT");
    print PLY3D "ply\n";
    print PLY3D "format ascii 1.0\n";
    print PLY3D "comment created by lulu the master of everything.\n";
    print PLY3D "element vertex 68\n";
    print PLY3D "property float x\n";
    print PLY3D "property float y\n";
    print PLY3D "property float z\n";
    print PLY3D "element face 0\n";
    print PLY3D "property list uchar int vertex_indices\n";
    print PLY3D "end_header\n";
    for ($p = 1 ;$p <= 68;$p++)
        {
        $line=<LANDMARK>;
        chop $line;
        @line=split(/,/,$line);
        print PLY3D "@line[0] @line[1] 0\n";
        }
    close PLY3D;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "DLIB $DLIBFLAG $ii took $hlat:$mlat:$slat\n";print RESET;
    }
}

if ($METHOD == 3)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $PRNDIR="$OOUTDIR/prnet";
    if (-e "$PRNDIR") {print "$PRNDIR already exists\n";}
    else {$cmd="mkdir $PRNDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
    $cmd="$PRNet -img $IIN -o $PRNDIR --isDlib True --isKpt True --isPose True --isTexture True --texture_size 512";
    verbose($cmd);
    system $cmd;
    
    $LANDMARK="$PRNDIR/$IN.$ii\_kpt.txt";
    open (LANDMARK , "$LANDMARK");
    
    $PLY3DOUT="$PRNDIR/$IN\_landmark.$ii.ply";
    print "writing $PLY3DOUT\n";
    open (PLY3D,">","$PLY3DOUT");
    print PLY3D "ply\n";
    print PLY3D "format ascii 1.0\n";
    print PLY3D "comment created by lulu the master of everything.\n";
    print PLY3D "element vertex 68\n";
    print PLY3D "property float x\n";
    print PLY3D "property float y\n";
    print PLY3D "property float z\n";
    print PLY3D "element face 0\n";
    print PLY3D "property list uchar int vertex_indices\n";
    print PLY3D "end_header\n";
    for ($p = 1 ;$p <= 68;$p++)
        {
        $line=<LANDMARK>;
        chop $line;
        @line=split(/,/,$line);
        print PLY3D "@line[0] @line[1] @line[2]\n";
        }
    close PLY3D;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "PRNet $ii took $hlat:$mlat:$slat\n";print RESET;
    }
}

if ($METHOD == 4)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $FACEDIR="$OOUTDIR/facealign";
    if (-e "$FACEDIR") {print "$FACEDIR already exists\n";}
    else {$cmd="mkdir $FACEDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
    $cmd="$FACEALIGN -detectFaces True -type $FACEALIGNTYPE -outputFormat txt -model $FACEMODELPATH/$FACEALIGNMODEL.t7 -modelZ $FACEMODELZ -input $IIN -device gpu -mode generate -output $FACEDIR";
    verbose($cmd);
    system $cmd;
    
    $LANDMARK="$FACEDIR/$IN.$ii.txt";
    open (LANDMARK , "$LANDMARK");
    
    $PLY3DOUT="$FACEDIR/$IN\_$FACEALIGNTYPE\_$FACEALIGNMODEL.$ii.ply";
    print "writing $PLY3DOUT\n";
    open (PLY3D,">","$PLY3DOUT");
    print PLY3D "ply\n";
    print PLY3D "format ascii 1.0\n";
    print PLY3D "comment created by lulu the master of everything.\n";
    print PLY3D "element vertex 68\n";
    print PLY3D "property float x\n";
    print PLY3D "property float y\n";
    print PLY3D "property float z\n";
    print PLY3D "element face 0\n";
    print PLY3D "property list uchar int vertex_indices\n";
    print PLY3D "end_header\n";
    for ($p = 1 ;$p <= 68;$p++)
        {
        $line=<LANDMARK>;
        chop $line;
        @line=split(/,/,$line);
        print PLY3D "@line[0] @line[1] @line[2]\n";
        }
    close PLY3D;
    $cmd="mv $LANDMARK $FACEDIR/$IN\_$FACEALIGNTYPE\_$FACEALIGNMODEL.$ii.txt";
    verbose($cmd);
    system $cmd;
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "FACEALIGN $ii took $hlat:$mlat:$slat\n";print RESET;
    }
}

if ($METHOD == 5)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $FACEDIR="$OOUTDIR/expression-net";
    if (-e "$FACEDIR") {print "$FACEDIR already exists\n";}
    else {$cmd="mkdir $FACEDIR";system $cmd;}
    $WORKDIR="$OOUTDIR/work_$$";
    if (-e "$WORKDIR") {verbose("$WORKDIR already exists");}
    else {$cmd="mkdir $WORKDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
    $cmd="$EXPRNet $WORKDIR $IIN $FACEDIR $OUT.$ii";
    verbose($cmd);
    system $cmd;
    
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "Expression-Net $ii took $hlat:$mlat:$slat\n";print RESET;
    }
}

if ($METHOD == 6)
{
    if ($OUT_USE_SHOT)
        {
        $OOUTDIR="$OUTDIR/$SHOT";
        }
    else
        {
        $OOUTDIR="$OUTDIR";
        }
    
    if (-e "$OOUTDIR") {verbose("$OOUTDIR already exists");}
    else {$cmd="mkdir $OOUTDIR";system $cmd;}
    $FACEDIR="$OOUTDIR/eos";
    if (-e "$FACEDIR") {print "$FACEDIR already exists\n";}
    else {$cmd="mkdir $FACEDIR";system $cmd;}
    $WORKDIR="$OOUTDIR/work_$$";
    if (-e "$WORKDIR") {verbose("$WORKDIR already exists");}
    else {$cmd="mkdir $WORKDIR";system $cmd;}
    
    for ($i = $FSTART ;$i <= $FEND; $i=$i+$FSTEP)
    {
    #-----------------------------#
    ($s1,$m1,$h1)=localtime(time);
    #-----------------------------#
        $ii=sprintf("%04d",$i);
        if ($IN_USE_SHOT)
            {
            $IIN="$INDIR/$SHOT/$IN.$ii.$EXTIN";
            }
        else
            {
            $IIN="$INDIR/$IN.$ii.$EXTIN";
            }
            
    #generate .txt from landmark.ply 
    $LANDMARK="$EOSMARKDIR/$EOSMARK.$ii.ply";
    open (LANDMARK , "$LANDMARK");
    print "reading $LANDMARK\n";
    #
    $TXTOUT="$WORKDIR/landmark.txt";
    print "writing $TXTOUT\n";
    open (TXT,">","$TXTOUT");
    print TXT "version: 1\n";
    print TXT "n_points:  68\n";
    print TXT "{\n";
    while ($line=<LANDMARK>)
    #for ($p = 1 ;$p <= 10;$p++)
        {
        #$line=<LANDMARK>;
        chop $line;
        #print "$line\n";
        if ($line eq "end_header") {last;}
        }
    for ($p = 1 ;$p <= 68;$p++)
        {
        $line=<LANDMARK>;
        chop $line;
        @line=split(/ /,$line);
        print TXT "@line[0] @line[1]\n";
        }
    print TXT "}\n";
    close TXT;
    close LANDMARK;
    #
    $cmd="$EOS -m $EOSMODEL -i $IIN -l $TXTOUT -p $EOSMAPPING -c $EOSCONTOUR -e $EOSEDGE -b $EOSBLEND -o $FACEDIR/$OUT.$ii";
    verbose($cmd);
    system $cmd;
    
    #-----------------------------#
    ($s2,$m2,$h2)=localtime(time);
    ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
    #afanasy parsing format
    print BOLD YELLOW "EOS $ii took $hlat:$mlat:$slat\n";print RESET;
    }
#
$cmd="rm -r $WORKDIR";
verbose($cmd);
system $cmd;
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
