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
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#defaults
$INDIR="$CWD";
$OUTDIR="$CWD/rushes";
$SIMULATE=0;
$VERBOSE=0;

sub verbose {
    if ($VERBOSE) {print BOLD GREEN "@_\n";print RESET}
}

sub isnum ($) {
#returns 0 if string 1 if number
#http://www.perlmonks.org/?node=How%20to%20check%20if%20a%20scalar%20value%20is%20numeric%20or%20string%3F
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1
}

#arguments
if ($#ARGV == -1) {
	print "usage: $scriptname \n";
	print "-indir [$INDIR]\n";
	print "-outdir [$OUTDIR]\n";
    print "-simulate\n";
	print "-verbose\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
  {
  if (@ARGV[$arg] eq "-indir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-outdir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
 if (@ARGV[$arg] eq "-simulate") 
    {
    $SIMULATE=1;
    print "simulate on\n";
    }
 if (@ARGV[$arg] eq "-verbose") 
    {
    $VERBOSE=1;
    print "verbose on\n";
    }
  }
  
if (-e "$OUTDIR") {print "$OUTDIR already exists\n";}
else {$cmd="mkdir $OUTDIR";print "$cmd\n";system $cmd;}

$userName =  $ENV{'USER'}; 
if (($userName eq "dev") || ($userName eq "render"))	#
  {
  $GMIC="/usr/bin/gmic";
  $FFMPEG="/usr/bin/ffmpeg";
  }
  
#look for subdir
opendir($dh, $INDIR);
@SUBDIR = grep { /^[^.]/ && -d "$INDIR/$_" } readdir($dh);
@SUBDIR = sort @SUBDIR;
closedir $dh;

foreach $DIR (@SUBDIR) {
    $DDIR="$INDIR/$DIR";
#    print "$DDIR\n";
    opendir($dh, $DDIR);
    @FILES = grep { /^[^.]/ && -f "$DDIR/$_" } readdir($dh);
    @FILES = sort @FILES;
    closedir $dh;
    #init imagename
    $IMAGE="";
    $FSTART=999999;
    $EXT="";
    foreach $FILE (@FILES) 
        {
        #print "     $FILE\n";
        @tmp=split(/\./,$FILE);
        $NUMBER=$tmp[$#tmp-1];
        $NNUMBER=int($NUMBER);
        if ($IMAGE eq "") {$IMAGE=$tmp[0];}
        if ($EXT eq "") {$EXT=$tmp[$#tmp];}
        $IIMAGE=$tmp[0];
        if ($IIMAGE ne $IMAGE)
            {
            print "$DDIR --> $IMAGE $FSTART $EXT\n";
            #make ffmpeg cmd
            $IIN="$DDIR/$IMAGE.\%04d.$EXT";
            $OUT="$OUTDIR/$DIR\_$IMAGE.mov";
            if ($EXT eq "exr") {$GAMMA="-gamma 2.2";}
            else {$GAMMA="";}
            $cmd="ffmpeg $GAMMA -start_number $FSTART -i $IIN -c:v prores -profile:v 3 $OUT";
            if (!$SIMULATE)
                {
                verbose $cmd;
                system $cmd;
                }
            $IMAGE=$IIMAGE;
            $EXT=$tmp[$#tmp];
            $FSTART=999999;
            }
        if ($NNUMBER < $FSTART) {$FSTART=$NNUMBER;}
        }
    #last seq
    print "$DDIR --> $IMAGE $FSTART $EXT\n";
    #make ffmpeg cmd
    $IIN="$DDIR/$IMAGE.\%04d.$EXT";
    $OUT="$OUTDIR/$DIR\_$IMAGE.mov";
    if ($EXT eq "exr") {$GAMMA="-gamma 2.2";}
    else {$GAMMA="";}
    $cmd="ffmpeg $GAMMA -start_number $FSTART -i $IIN -c:v prores -profile:v 3 $OUT";
    if (!$SIMULATE)
        {
        verbose $cmd;
        system $cmd;
        }
}

