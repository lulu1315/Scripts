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

if ($#ARGV == -1) {
	print "usage: GRADING.pl \n";
	print "-i imagein\n";
	print "-odir dirout\n";
	print "-BWfilms   [B&W films]        25x\n";
    print "-FilterGradeCinematic         8x\n";
    print "-FujiXtrans  [Fuji Xtrans]    6x\n";
	print "-InstantC  [Instant consumer] 54x\n";
	print "-InstantP  [Instant pro]      67x\n";
	print "-NegativeC [Negative color]   12x\n";
	print "-NegativeN [Negative new]     9x\n";
	print "-NegativeO [Negative old]     11x\n";
	print "-PictureFX [PictureFX]        19x\n";
	print "-PrintF    [Print films]      12x\n";
    print "-RocketStock [RocketStock]    35x\n";
	print "-SlideC    [Slide color]      26x\n";
	print "-Various   [Various]          62x\n";
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
  if (@ARGV[$arg] eq "-BWfilms") 
    {
    $BWfilms=1;
    print "grading for BWfilms ... \n";
    }
  if (@ARGV[$arg] eq "-FilterGradeCinematic") 
    {
    $FilterGradeCinematic=1;
    print "grading for FilterGradeCinematic ... \n";
    }
  if (@ARGV[$arg] eq "-FujiXtrans") 
    {
    $FujiXtrans=1;
    print "grading for FujiXtrans ... \n";
    }
  if (@ARGV[$arg] eq "-InstantC") 
    {
    $InstantC=1;
    print "grading for InstantC ... \n";
    }
  if (@ARGV[$arg] eq "-InstantP") 
    {
    $InstantP=1;
    print "grading for InstantP ... \n";
    }
  if (@ARGV[$arg] eq "-NegativeC") 
    {
    $NegativeC=1;
    print "grading for NegativeC ... \n";
    }
  if (@ARGV[$arg] eq "-NegativeN") 
    {
    $NegativeN=1;
    print "grading for NegativeN ... \n";
    }
  if (@ARGV[$arg] eq "-NegativeO") 
    {
    $NegativeO=1;
    print "grading for NegativeO ... \n";
    }
  if (@ARGV[$arg] eq "-PictureFX") 
    {
    $PictureFX=1;
    print "grading for PictureFX ... \n";
    }
  if (@ARGV[$arg] eq "-PrintF") 
    {
    $PrintF=1;
    print "grading for PrintF ... \n";
    }
  if (@ARGV[$arg] eq "-RocketStock") 
    {
    $RocketStock=1;
    print "grading for RocketStock ... \n";
    }
  if (@ARGV[$arg] eq "-SlideC") 
    {
    $SlideC=1;
    print "grading for SlideC ... \n";
    }
  if (@ARGV[$arg] eq "-Various") 
    {
    $Various=1;
    print "grading for Various ... \n";
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
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_bw $i,100,0,0,0,0,0,0,0,0";
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
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_filtergrade $i,100,0,0,0,0,0,0,0,0";
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
  
if ($FujiXtrans || $ALL)
  {
  $PRESETS=6;
  $EXTENSION="FujiXtrans";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_fujixtransii $i,100,0,0,0,0,0,0,0,0";
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
  
if ($InstantC || $ALL)
  {
  $PRESETS=54;
  $EXTENSION="InstantC";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_instant_consumer $i,100,0,0,0,0,0,0,0";
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
  
if ($InstantP || $ALL)
  {
  $PRESETS=67;
  $EXTENSION="InstantP";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_instant_pro $i,100,0,0,0,0,0,0,0";
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
  
if ($NegativeC || $ALL)
  {
  $PRESETS=12;
  $EXTENSION="NegativeC";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_negative_color $i,100,0,0,0,0,0,0,0";
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
  
if ($NegativeN || $ALL)
  {
  $PRESETS=9;
  $EXTENSION="NegativeN";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_negative_new $i,1,100,0,0,0,0,0,0,0";
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

if ($NegativeO || $ALL)
  {
  $PRESETS=11;
  $EXTENSION="NegativeO";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_negative_old $i,1,100,0,0,0,0,0,0,0";
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
  
if ($PictureFX || $ALL)
  {
  $PRESETS=19;
  $EXTENSION="PictureFX";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_picturefx $i,100,0,0,0,0,0,0,0";
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
  
if ($PrintF || $ALL)
  {
  $PRESETS=12;
  $EXTENSION="PrintF";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_print $i,100,0,0,0,0,0,0,0";
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
  
if ($SlideC || $ALL)
  {
  $PRESETS=26;
  $EXTENSION="SlideC";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_colorslide $i,100,0,0,0,0,0,0,0";
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
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_rocketstock $i,100,0,0,0,0,0,0,0";
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
  
if ($Various || $ALL)
  {
  $PRESETS=62;
  $EXTENSION="Various";
  if (-e "$OUTDIR/$EXTENSION") {print "$OUTDIR/$EXTENSION already exists\n";}
  else {$cmd="mkdir $OUTDIR/$EXTENSION";system $cmd;}
  for ($i = 1 ;$i <= $PRESETS;$i++)
    {
    $OP="-fx_emulate_film_various $i,100,0,0,0,0,0,0,0";
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
