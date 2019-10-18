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
$IN_USE_SHOT=0;
$OUT_USE_SHOT=0;
$SHOT="";
$CONTENTDIR="$CWD/originales";
$CONTENT="ima";
$STYLEDIR="$CWD/styles";
$STYLE="style.jpg";
$STYLESIZE=0;
$OUTDIR="$CWD/colortransfert";
$ZEROPAD=1;
$FORCE=0;
$EXT="png";
$VERBOSE=0;
#
$SIZE=0;
$METHOD=3;
$LCTMODE="pca";
$MONTAGE=0;
#preprocess
$ROLLING=0;
$BRIGHTNESS=0;
$CONTRAST=0;
$GAMMA=0;
$SATURATION=0;
$DOLOCALCONTRAST=0;
#postprocess
$DOINDEX=0;
$INDEXCOLOR=64;
$INDEXMETHOD=1;
$DITHERING=1;
$INDEXROLL=5;

$GPU=0;
$CLEAN=1;
$CSV=0;
$LOG1=" > /var/tmp/colortransfert.log";
$LOG2=" 2> /var/tmp/colortransfert.log";

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
print AUTOCONF confstr(CONTENTDIR);
print AUTOCONF confstr(CONTENT);
print AUTOCONF confstr(STYLEDIR);
print AUTOCONF confstr(STYLE);
print AUTOCONF confstr(STYLESIZE);
print AUTOCONF confstr(OUTDIR);
print AUTOCONF confstr(SHOT);
print AUTOCONF confstr(IN_USE_SHOT);
print AUTOCONF confstr(OUT_USE_SHOT);
print AUTOCONF confstr(ZEROPAD);
print AUTOCONF confstr(FORCE);
print AUTOCONF confstr(EXT);
print AUTOCONF confstr(VERBOSE);
print AUTOCONF "#transfert\n";
print AUTOCONF confstr(SIZE);
print AUTOCONF confstr(METHOD);
print AUTOCONF "#0 : all methods\n";
print AUTOCONF "#1 : color_transfer\n";
print AUTOCONF "#2 : hmap\n";
print AUTOCONF "#3 : Neural-tools\n";
print AUTOCONF "#4 : ideepcolor\n";
print AUTOCONF "#5 : indexing\n";
print AUTOCONF confstr(LCTMODE);
print AUTOCONF "#preprocess\n";
print AUTOCONF confstr(ROLLING);
print AUTOCONF confstr(BRIGHTNESS);
print AUTOCONF confstr(CONTRAST);
print AUTOCONF confstr(GAMMA);
print AUTOCONF confstr(SATURATION);
print AUTOCONF confstr(DOLOCALCONTRAST);
print AUTOCONF "#postprocess (method 3 only)\n";
print AUTOCONF confstr(DOINDEX);
print AUTOCONF confstr(INDEXCOLOR);
print AUTOCONF confstr(INDEXMETHOD);
print AUTOCONF confstr(DITHERING);
print AUTOCONF confstr(INDEXROLL);
print AUTOCONF "#misc\n";
print AUTOCONF confstr(GPU);
print AUTOCONF confstr(CLEAN);
print AUTOCONF confstr(CSV);
#print AUTOCONF "\$PARAMS=\"_m\$METHOD\"\;\n";
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
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-autoconf") 
    {
    print "writing $scriptname\_auto.conf --> mv $scriptname\_auto.conf $scriptname.conf\n";
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
    if (-e "$STYLEDIR") {print "$STYLEDIR already exists\n";}
    else {$cmd="mkdir $STYLEDIR";system $cmd;}
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
if (($userName eq "dev") || ($userName eq "render"))	#
  {
  $GMIC="/shared/foss/gmic/src/gmic";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="python3 /shared/foss/Neural-Tools/linear-color-transfer.py";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $cmd="echo \"\" > ~/.pyenv/version";
  print "$cmd\n";
  system $cmd;
  $ENV{PYTHONPATH} = "/shared/foss/caffe/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
if ($userName eq "dev18")	#
  {
  if ($HOSTNAME =~ "hp") {$GPU=-1}
  $GMIC="/usr/bin/gmic";
  $COLOR_TRANSFER="/shared/foss-18/color_transfer/color_transfer.py";
  $HMAP="/shared/foss-18/hmap/hmap.py";
  $LINEARCOLORTRANSFERT="python3 /shared/foss-18/Neural-Tools/linear-color-transfer.py";
  $IDEEPCOLOR="/usr/bin/python3 /shared/foss-18/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss-18/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss-18/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss-18/ideepcolor/models/global_model/dummy.caffemodel";
  if ($HOSTNAME =~ "hp") {
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe-cpu/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe-cpu/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  }
  else
  {
  $ENV{PYTHONPATH} = "/shared/foss-18/caffe/python:/shared/foss-18/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
  $ENV{LD_LIBRARY_PATH} = "/shared/foss-18/caffe/build/lib:$ENV{'LD_LIBRARY_PATH'}";
  }
  verbose("PYTHONPATH : $ENV{'PYTHONPATH'}");
  }
  
if ($userName eq "lulu")	#
  {
  $GMIC="/usr/bin/gmic";
  $COLOR_TRANSFER="/shared/foss/color_transfer/color_transfer.py";
  $HMAP="/shared/foss/hmap/hmap_c.py";
  $LINEARCOLORTRANSFERT="python3 /shared/foss/Neural-Tools/linear-color-transfer.py";
  $IDEEPCOLOR="/usr/bin/python /shared/foss/ideepcolor/GlobalHistogramTransfer.py";
  $PROTOTXT="/shared/foss/ideepcolor/models/global_model/deploy_nodist.prototxt";
  $CAFFEMODEL="/shared/foss/ideepcolor/models/global_model/global_model.caffemodel";
  $GLOBPROTOTXT="/shared/foss/ideepcolor/models/global_model/global_stats.prototxt";
  $GLOBCAFFEMODEL="/shared/foss/ideepcolor/models/global_model/dummy.caffemodel";
  $ENV{PYTHONPATH} = "/shared/foss/caffe/python:/shared/foss/ideepcolor/caffe_files:$ENV{'PYTHONPATH'}";
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
    
$OOUTDIR="$OUTDIR/$SHOT";
if (-e "$OOUTDIR") {print "$OOUTDIR already exists\n";}
else {$cmd="mkdir $OOUTDIR";system $cmd;}

#finalframe
$SSTYLE=$STYLE;
$SSTYLE=~ s/.jpg//;
$SSTYLE=~ s/.jpeg//;
$SSTYLE=~ s/.png//;
$SSTYLE=~ s/\.//;
@tmp=split(/\./,$CONTENT);
$CCONTENT=@tmp[0];

for ($i=$FSTART ; $i <= $FEND ; $i++)
{
$ii=sprintf("%04d",$i);

#if (($METHOD == 1) || ($METHOD == 0))
if ($METHOD == 1)
#pip install color_transfer
    {
    $PARAMS="_m1";
    $WORKDIR="$OOUTDIR/w$ii$PARAMS";
    if ($IN_USE_SHOT) {$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";} else {$INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXT";}
    $INSTYLE="$STYLEDIR/$STYLE";
    $OOUT="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";
    if (-e $OOUT && !$FORCE)
        {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
    else
        {
        $touchcmd="touch $OOUT";
        system $touchcmd;
        $MONTAGE=1;
        print BOLD BLUE ("\nframe : $ii\n");print RESET;
        if ($STYLESIZE)
            {
            if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
            $cmd="$GMIC -i $INSTYLE -resize2dx $STYLESIZE,5 -o $WORKDIR/style.png";
            verbose($cmd);
            print("--------> resize style [size:$INSTYLE]\n");
            system $cmd;
            $INSTYLE="$WORKDIR/style.png";
            }
        if ($SIZE)
            {$GMIC1="-resize2dx $SIZE,5";} else {$GMIC1="";}
        if ($DOLOCALCONTRAST)
            {$GMIC2="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC2="";}
        if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
            {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
            else {$GMIC3="";}
        if ($ROLLING) 
            {$GMIC4="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC4="";}
        if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        $cmd="$GMIC -i $INCONTENT $GMIC1 $GMIC2 $GMIC3 $GMIC4 -o $WORKDIR/content.$EXT $LOG2";
        verbose($cmd);
        print("--------> preprocess content [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
        system $cmd;
        $INCONTENT="$WORKDIR/content.$EXT";
        #
        $cmd="python3 $COLOR_TRANSFER -s $INSTYLE -t $INCONTENT -o $OOUT";
        verbose($cmd);
        print("--------> color_transfert\n");
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        system $cmd;
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat \n";print RESET;
        #-----------------------------#
        clean();
        }
    }
    
#if (($METHOD == 2) || ($METHOD == 0))
if ($METHOD == 2)
#pip install Pillow
    {
    $PARAMS="_m2";
    $WORKDIR="$OUTDIR/w$ii$PARAMS";
    if ($IN_USE_SHOT) {$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";} else {$INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXT";}
    $INSTYLE="$STYLEDIR/$STYLE";
    $OOUT="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";
    if (-e $OOUT && !$FORCE)
        {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
    else
        {
        $touchcmd="touch $OOUT";
        system $touchcmd;
        $MONTAGE=1;
        print BOLD BLUE ("\nframe : $ii\n");print RESET;
        if ($STYLESIZE)
            {
            if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
            $cmd="$GMIC -i $INSTYLE -resize2dx $STYLESIZE,5 -o $WORKDIR/style.png $LOG2";
            verbose($cmd);
            print("--------> resize style [size:$INSTYLE]\n");
            system $cmd;
            $INSTYLE="$WORKDIR/style.png";
            }
        if ($SIZE)
            {$GMIC1="-resize2dx $SIZE,5";} else {$GMIC1="";}
        if ($DOLOCALCONTRAST)
            {$GMIC2="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC2="";}
        if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
            {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
            else {$GMIC3="";}
        if ($ROLLING) 
            {$GMIC4="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC4="";}
        if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        $cmd="$GMIC -i $INCONTENT $GMIC1 $GMIC2 $GMIC3 $GMIC4 -o $WORKDIR/content.$EXT $LOG2";
        verbose($cmd);
        print("--------> preprocess content [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
        system $cmd;
        $INCONTENT="$WORKDIR/content.$EXT";
        #
        $cmd="python $HMAP $INCONTENT $INSTYLE $OOUT";
        verbose($cmd);
        print("--------> hmap\n");
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        system $cmd;
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat \n";print RESET;
        #-----------------------------#
        clean();
        }
    }
    
if (($METHOD == 3) || ($METHOD == 0))
    {
    $PARAMS="_m3";
    $WORKDIR="$OOUTDIR/w$ii$PARAMS";
    if ($IN_USE_SHOT) {$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";} else {$INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXT";}
    $INSTYLE="$STYLEDIR/$STYLE";
    $OOUT="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";
    if (-e $OOUT && !$FORCE)
        {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
    else
        {
        $touchcmd="touch $OOUT";
        system $touchcmd;
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        $MONTAGE=1;
        print BOLD BLUE ("\nframe : $ii\n");print RESET;
        if ($STYLESIZE)
            {
            if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
            $cmd="$GMIC -i $INSTYLE -resize2dx $STYLESIZE,5 -o $WORKDIR/style.png $LOG2";
            verbose($cmd);
            print("--------> resize style [size:$INSTYLE]\n");
            system $cmd;
            $INSTYLE="$WORKDIR/style.png";
            }
        if ($SIZE)
            {$GMIC1="-resize2dx $SIZE,5";} else {$GMIC1="";}
        if ($DOLOCALCONTRAST)
            {$GMIC2="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC2="";}
        if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
            {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
            else {$GMIC3="";}
        if ($ROLLING) 
            {$GMIC4="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC4="";}
        if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        $cmd="$GMIC -i $INCONTENT $GMIC1 $GMIC2 $GMIC3 $GMIC4 -o $WORKDIR/content.$EXT $LOG2 $LOG2";
        verbose($cmd);
        print("--------> preprocess content [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
        system $cmd;
        $INCONTENT="$WORKDIR/content.$EXT";
        #
        $cmd="$LINEARCOLORTRANSFERT --mode $LCTMODE --target_image $INCONTENT --source_image $INSTYLE --output_image $OOUT $LOG2";
        verbose($cmd);
        print("--------> linear color transfert [mode:$LCTMODE]\n");
        system $cmd;
        if ($DOINDEX)
            {
            $cmd="$GMIC $INSTYLE -colormap $INDEXCOLOR,$INDEXMETHOD,1 $OOUT -index[1] [0],1,$DITHERING -remove[0] -fx_sharp_abstract $INDEXROLL,10,0.5,0,0 -o $OOUT $LOG2";
            verbose($cmd);
            print("--------> indexing [colors:$INDEXCOLOR method:$INDEXMETHOD dither:$DITHERING rolling:$INDEXROLL]\n");
            system $cmd;
            }
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat \n";print RESET;
        #-----------------------------#
        clean();
        }
    }
    
if (($METHOD == 4) || ($METHOD == 0))
    {
    $PARAMS="_m4";
    $WORKDIR="$OOUTDIR/w$ii$PARAMS";
    if ($IN_USE_SHOT) {$INCONTENT="$CONTENTDIR/$SHOT/$CONTENT.$ii.$EXT";} else {$INCONTENT="$CONTENTDIR/$CONTENT.$ii.$EXT";}
    $INSTYLE="$STYLEDIR/$STYLE";
    $OOUT="$OOUTDIR/$CCONTENT\_$SSTYLE$PARAMS.$ii.$EXT";
    if (-e $OOUT && !$FORCE)
        {print BOLD RED "frame $OOUT exists ... skipping\n";print RESET;}
    else
        {
        $touchcmd="touch $OOUT";
        system $touchcmd;
        $MONTAGE=1;
        print BOLD BLUE ("\nframe : $ii\n");print RESET;
        if ($STYLESIZE)
            {
            if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
            $cmd="$GMIC -i $INSTYLE -resize2dx $STYLESIZE,5 -o $WORKDIR/style.png $LOG2";
            verbose($cmd);
            print("--------> resize style [size:$INSTYLE]\n");
            system $cmd;
            $INSTYLE="$WORKDIR/style.png";
            }
        if ($SIZE)
            {$GMIC1="-resize2dx $SIZE,5";} else {$GMIC1="";}
        if ($DOLOCALCONTRAST)
            {$GMIC2="-fx_LCE[0] 80,0.5,1,1,0,0";} else {$GMIC2="";}
        if ($BRIGHTNESS || $CONTRAST || $GAMMA || $SATURATION) 
            {$GMIC3="-fx_adjust_colors $BRIGHTNESS,$CONTRAST,$GAMMA,0,$SATURATION";} 
            else {$GMIC3="";}
        if ($ROLLING) 
            {$GMIC4="-fx_sharp_abstract $ROLLING,10,0.5,0,0";} else {$GMIC4="";}
        if (!-e $WORKDIR) {$cmd="mkdir $WORKDIR";system $cmd;}
        $cmd="$GMIC -i $INCONTENT $GMIC1 $GMIC2 $GMIC3 $GMIC4 -to_colormode 1 -o $WORKDIR/content.$EXT $LOG2";
        verbose($cmd);
        print("--------> preprocess content [size:$SIZE lce:$DOLOCALCONTRAST rolling:$ROLLING bcgs:$BRIGHTNESS/$CONTRAST/$GAMMA/$SATURATION]\n");
        system $cmd;
        $INCONTENT="$WORKDIR/content.$EXT";
        #
        $cmd="$IDEEPCOLOR $INCONTENT $INSTYLE $OOUT $PROTOTXT $CAFFEMODEL $GLOBPROTOTXT $GLOBCAFFEMODEL $GPU 2> /var/tmp/colortransfert.log";
        verbose($cmd);
        print("--------> ideepcolor]\n");
        #-----------------------------#
        ($s1,$m1,$h1)=localtime(time);
        #-----------------------------#
        system $cmd;
        #-----------------------------#
        ($s2,$m2,$h2)=localtime(time);
        ($slat,$mlat,$hlat) = lapse($s1,$m1,$h1,$s2,$m2,$h2);
        print BOLD YELLOW "Writing $OOUT took $hlat:$mlat:$slat \n";print RESET;
        #-----------------------------#
        clean();
        }
    }

    if ($MONTAGE && ($METHOD == 0))
        {
        $M1="$OOUTDIR/$CCONTENT\_$SSTYLE\_m1.$ii.$EXT";
        $M2="$OOUTDIR/$CCONTENT\_$SSTYLE\_m2.$ii.$EXT";
        $M3="$OOUTDIR/$CCONTENT\_$SSTYLE\_m3.$ii.$EXT";
        $M4="$OOUTDIR/$CCONTENT\_$SSTYLE\_m4.$ii.$EXT";
        $cmd="$GMIC $M1 $M2 $M3 $M4 -text_outline[0] \"1\" -text_outline[1] \"2\" -text_outline[2] \"3\" -text_outline[3] \"4\" -montage X -o $OOUTDIR/$CCONTENT\_$SSTYLE\_montage.$ii.$EXT $LOG2";
        verbose($cmd);
        #system $cmd;
        $MONTAGE=0;
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
    $STYLE=@line[1];
    #$VERSION=@line[2];
    $FSTART=@line[3];
    $FEND=@line[4];
    $LENGTH=@line[5];   
    $process=@line[6];
    $suffix=@line[7];
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
  
sub clean
{
if ($CLEAN)
    {
    $cleancmd="rm -r $WORKDIR";
    verbose($cleancmd);
    system $cleancmd;
    }
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
