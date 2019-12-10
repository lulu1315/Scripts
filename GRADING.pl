#!/usr/bin/perl

use Cwd 'abs_path';
$myscript = abs_path($0);
print "script : $myscript\n";

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print "project : $PROJECT\n";

$IN="ima";
$OUTDIR="$CWD/grading";
$VERBOSE=0;
$EXTOUT="png";
$FORCE=0;
$ALL=0;

$InstantConsumer=0;
$InstantPro=0;
$FujiXTransIII=0;
$NegativeColor=0;
$NegativeNew=0;
$NegativeOld=0;
$PrintFilm=0;
$SlideColor=0;
$AbigailGonzales=0;
$AlexJordan=0;
$CreativePack=0;
$EricEllerbrock=0;
$FilterGradeCinematic=0;
$JTSemple=0;
$LutifyMe=0;
$Moviz=0;
$OhadPeretz=0;
$ON1Photography=0;
$PictureFx=0;
$PIXLSUS=0;
$RocketStock=0;
$ShamoonAbbasi=0;
$SmallHDMovieLook=0;
$Others=0;

if ($#ARGV == -1) {
	print "usage: GRADING.pl \n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-Tone      [TonePresets]      8x\n";
	print "-all       [all presets]\n";
	print "-force [0]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
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
  if (@ARGV[$arg] eq "-Tone") 
    {
    $Tone=1;
    print "grading for Tone ... \n";
    }
  if (@ARGV[$arg] eq "-all") 
    {
    $ALL=1;
    print "grading for all presets ... \n";
    }
 if (@ARGV[$arg] eq "-force") 
    {
    $FORCE=1;
    print "force output ...\n";
    }
  }
  
$userName =  $ENV{'USER'}; 
if ($userName eq "dev18" || $userName eq "render")	#
  {
  $GMIC="/usr/bin/gmic";
  }
if ($userName eq "luluf")	#
  {
  $GMIC="/usr/bin/gmic";
  }
if ($userName eq "lulu")	#
  {
  $GMIC="/usr/bin/gmic";
  }

@tmp=split(/\//,$IN);
$IIN=$tmp[$#tmp];
@tmp=split(/\./,$IIN);
$IMANAME=@tmp[0];
$IMAEXT=@tmp[$#tmp];
print "image name : $IMANAME\n";
print "image type : $IMAEXT\n";

if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";system $cmd;}

if ($IMAEXT eq "exr")
  {
  $convertcmd = "convert $IN -colorspace sRGB $OUTDIR/$IMANAME.jpg";
  system $convertcmd;
  $IN = "$OUTDIR/$IMANAME.jpg";
  }

if ($BWfilms || $ALL)
  {
  $PRESETS=25;
  $EXTENSION="BWfilms";
  $CODE=0;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,$i,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($InstantConsumer || $ALL)
  {
  $PRESETS=54;
  $EXTENSION="InstantConsumer";
  $CODE=1;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,$i,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($InstantPro || $ALL)
  {
  $PRESETS=68;
  $EXTENSION="InstantPro";
  $CODE=2;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,$i,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($FujiXTransIII || $ALL)
  {
  $PRESETS=15;
  $EXTENSION="FujiXTransIII";
  $CODE=3;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,$i,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($NegativeColor || $ALL)
  {
  $PRESETS=13;
  $EXTENSION="NegativeColor";
  $CODE=4;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,0,$i,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($NegativeNew || $ALL)
  {
  $PRESETS=39;
  $EXTENSION="NegativeNew";
  $CODE=5;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,0,0,$i,0,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($NegativeOld || $ALL)
  {
  $PRESETS=44;
  $EXTENSION="NegativeOld";
  $CODE=6;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,$i,0,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }

if ($PrintFilm || $ALL)
  {
  $PRESETS=12;
  $EXTENSION="PrintFilm";
  $CODE=7;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,$i,0,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($SlideColor || $ALL)
  {
  $PRESETS=26;
  $EXTENSION="SlideColor";
  $CODE=8;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,0,0,50,50 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_simulate_film $CODE,0,0,0,0,0,0,0,0,$i,512,100,0,0,0,0,0,0,0,50,50";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
#COLOR PRESETS
if ($AbigailGonzales || $ALL)
  {
  $PRESETS=21;
  $EXTENSION="AbigailGonzales";
  $CODE=0;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,$i,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($AlexJordan || $ALL)
  {
  $PRESETS=81;
  $EXTENSION="AlexJordan";
  $CODE=1;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,$i,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($CreativePack || $ALL)
  {
  $PRESETS=33;
  $EXTENSION="CreativePack";
  $CODE=2;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,$i,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($EricEllerbrock || $ALL)
  {
  $PRESETS=14;
  $EXTENSION="EricEllerbrock";
  $CODE=3;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,$i,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($FilterGradeCinematic || $ALL)
  {
  $PRESETS=8;
  $EXTENSION="FilterGradeCinematic";
  $CODE=4;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,$i,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($JTSemple || $ALL)
  {
  $PRESETS=14;
  $EXTENSION="JTSemple";
  $CODE=5;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,$i,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($LutifyMe || $ALL)
  {
  $PRESETS=7;
  $EXTENSION="LutifyMe";
  $CODE=6;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,$i,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($Moviz || $ALL)
  {
  $PRESETS=48;
  $EXTENSION="Moviz";
  $CODE=7;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,$i,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($OhadPeretz || $ALL)
  {
  $PRESETS=7;
  $EXTENSION="OhadPeretz";
  $CODE=8;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,$i,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($ON1Photography || $ALL)
  {
  $PRESETS=90;
  $EXTENSION="ON1Photography";
  $CODE=9;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,$i,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($PictureFx || $ALL)
  {
  $PRESETS=19;
  $EXTENSION="PictureFx";
  $CODE=10;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,$i,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($PIXLSUS || $ALL)
  {
  $PRESETS=31;
  $EXTENSION="PIXLSUS";
  $CODE=11;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,$i,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($RocketStock || $ALL)
  {
  $PRESETS=35;
  $EXTENSION="RocketStock";
  $CODE=12;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,$i,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($ShamoonAbbasi || $ALL)
  {
  $PRESETS=25;
  $EXTENSION="ShamoonAbbasi";
  $CODE=13;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,$i,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($SmallHDMovieLook || $ALL)
  {
  $PRESETS=7;
  $EXTENSION="SmallHDMovieLook";
  $CODE=14;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,$i,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($Others || $ALL)
  {
  $PRESETS=69;
  $EXTENSION="Others";
  $CODE=15;
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  #collage
  $OUT="$OUTDIR/$EXTENSION\_collage.$EXTOUT";
  if (-e "$OUT" && !$FORCE)
      {print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;}
    else
      {
      $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0 -remove[0]";
      $cmd="$GMIC -i $IN -$OP -o $OUT";
      system $cmd;
      }
  #all effects
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_color_presets $CODE,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,$i,512,100,0,0,0,0,0,3,0,50,50,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
  
if ($Tone || $ALL)
  {
  $PRESETS=8;
  $EXTENSION="Tone";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 0 ;$i < $PRESETS;$i++)
    {
    $OP="-iain_tone_presets_p $i,100,0,0";
    $OUT="$OUTDIR/$EXTENSION/$IMANAME\_$EXTENSION\_$i.$EXTOUT";
    if (-e "$OUT" && !$FORCE)
      {
      print BOLD GREEN "$OUT exists , skipping ....\n";print RESET;
      }
    else
      {
      @tmp=split(/ /,$OP);
      $cmd="$GMIC -i $IN -$OP -text_outline[0]  \"@tmp[0] $i\" -montage H -o $OUT";
      #print "$cmd\n";
      system $cmd;
      }
    }
  }
