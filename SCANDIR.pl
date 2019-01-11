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
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

sub isnum ($) {
#returns 0 if string 1 if number
#http://www.perlmonks.org/?node=How%20to%20check%20if%20a%20scalar%20value%20is%20numeric%20or%20string%3F
    return 0 if $_[0] eq '';
    $_[0] ^ $_[0] ? 0 : 1
}

#defaults
$INDIR="./originales";
$OUTDIR="./";
$ZEROPAD=1;
$EXT="png";
$FORMAT="csv";
$PRORESCODEC="-c:v prores -profile:v 3";
$H264CODEC="-c:v libx264 -crf 15 -pix_fmt yuv420p";
$EXECUTE=0;
$VERBOSE=1;

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-idir dirin [$INDIR]\n";
	print "-odir dirout [$OUTDIR]\n";
	print "-ext image extension [$EXT]\n";
    print "-format [$FORMAT] ffmpeg_prores ffmpeg_h264\n";
    print "-exec : execute command (ffmpeg only) [$EXECUTE]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
{
  if (@ARGV[$arg] eq "-idir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-odir") 
    {
    $OUTDIR=@ARGV[$arg+1];
    print "out dir : $OUTDIR\n";
    }
  if (@ARGV[$arg] eq "-ext") 
    {
    $EXT=@ARGV[$arg+1];
    print "image extension : $EXT\n";
    }
  if (@ARGV[$arg] eq "-format") 
    {
    $FORMAT=@ARGV[$arg+1];
    print "output format : $FORMAT\n";
    }
  if (@ARGV[$arg] eq "-exec") 
    {
    $EXECUTE=1;
    print "execute command\n";
    }
}

#open indir
opendir INDIR, "$INDIR";
#keep only shots
@shots = readdir INDIR;
#@shots = grep { /P/ } readdir INDIR;
closedir INDIR;

foreach $shot (sort { substr($a, 1) <=> substr($b, 1) } @shots) 
    { 
    if (-d "$CWD/$INDIR/$shot") #make sure it is a directory
        {
        #print "scanning shot : $shot\n";
        opendir SHOT, "$INDIR/$shot";
        @images = grep { /$EXT/ } readdir SHOT;
        closedir SHOT;
        %seen = ();
        @uniq = ();
        foreach $image (@images) 
            {
            @tmp=split(/\./,$image);
            if ($#tmp >= 2)
                {
                #$imaroot=@tmp[$#tmp-2];
                $imaroot=join '.', @tmp[0 .. $#tmp-2];
                #print ("$imaroot\n");
                unless ($seen{$imaroot}) 
                    {
                    $seen{$imaroot} = 1;
                    push(@uniq, $imaroot);
                    }
                }
            }
        }
        foreach $root (@uniq) 
            {
            #reread image seq
            opendir SHOT, "$INDIR/$shot";
            @images = grep { /$root/ } readdir SHOT;
            closedir SHOT;
            $min=9999999;
            $max=-1;
            foreach $image (@images) 
                { 
                #print ("$ima\n");
                @tmp=split(/\./,$image);
                if ($#tmp >= 2)
                    {
                    $numframe=int($tmp[$#tmp-1]);
                    #print ("$numframe\n");
                    if ($numframe > $max) {$max = $numframe;}
                    if ($numframe < $min) {$min = $numframe;}
                    }
                }
            if ($FORMAT eq "csv")
                {
                print ("$shot,$root,%04d,$EXT,$min,$max\n");
                }
            if ($FORMAT eq "ffmpeg_prores")
                {
                $cmd = "ffmpeg -start_number $min -i $CWD/$INDIR/$shot/$root.%04d.$EXT $PRORESCODEC $OUTDIR/$shot\_$root.mov";
                print ("$cmd\n");
                if ($EXECUTE) {system ($cmd);}
                }
            if ($FORMAT eq "ffmpeg_h264")
                {
                $cmd = "ffmpeg -start_number $min -i $CWD/$INDIR/$shot/$root.%04d.$EXT $H264CODEC $shot\_$root.mp4";
                print ("$cmd\n");
                if ($EXECUTE) {system ($cmd);}
                }
            }
    }
