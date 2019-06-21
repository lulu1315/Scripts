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

#-vf "scale=w=5400:h=1920" -sws_flags bicubic -c:v hap -chunks 16
#defaults
$INDIR="./originales";
$OUTDIR="./";
$ZEROPAD=1;
$EXT="png";
$FORMAT="csv";
$PRORESCODEC="-c:v prores_ks -profile:v 3";
$H264CODEC="-c:v libx264 -crf 10 -pix_fmt yuv420p";
$H264CODEC="-c:v libx264 -crf 10";
$DNXCODEC="-c:v dnxhd -b:v 120M -pix_fmt yuv422p";
$HAPCODEC="-c:v hap -chunks 16";
$EXECUTE=0;
$VERBOSE=1;

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-idir dirin [$INDIR]\n";
	print "-odir dirout [$OUTDIR]\n";
	print "-ext image extension [$EXT]\n";
    print "-format [$FORMAT] prores h264 dnx_120 hap\n";
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
  if (@ARGV[$arg] eq "-csv") 
    {
    $CSVFILE=@ARGV[$arg+1];
    print "csv file: $CSV\n";
    }
}

#$OUTDIR="$INDIR\_dnx120";
#$OUTDIR="$INDIR\_prores";
#$OUTDIR="$INDIR\_hap";

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
            encode();
            }
        }
        
sub encode {  
if ($FORMAT eq "hap")
    {
    print "encoding $FORMAT\n";
    $RESIZEFILTER="scale=w=5400:h=1920";
    $FILTER="-sws_flags bicubic";
    $cmd="ffmpeg -i $INDIR/$SHOT.%04d.png -vf \"$RESIZEFILTER\" $FILTER $HAPCODEC $OUTDIR/$SHOT\_hap.mov";
    }
if ($FORMAT eq "prores")
    {
    print "encoding $FORMAT\n";
    $cmd="ffmpeg -i $INDIR/$SHOT.%04d.png $PRORESCODEC $OUTDIR/$SHOT\_prores.mov";
    }
if ($FORMAT eq "h264")
    {
    print "encoding $FORMAT\n";
    $cmd="ffmpeg -i $INDIR/$SHOT.%04d.png $H264CODEC $OUTDIR/$SHOT\_h264.mov";
    }
if ($FORMAT eq "dnx_120")
    {
    print "encoding $FORMAT\n";
    $RESIZEFILTER="scale=w=1920:h=1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2";
    $STAMPFILTER="drawtext=fontfile=/usr/share/fonts/truetype/tlwg/Sawasdee.ttf: text='$SHOT.mov \%{frame_num}': start_number=1: x=(w-tw)/2: y=h-(2*lh): fontcolor=white: fontsize=40: alpha=.5";
    $cmd="ffmpeg -i $INDIR/$SHOT.%04d.png -vf \"$RESIZEFILTER,$STAMPFILTER\" $DNXCODEC $OUTDIR/$SHOT\_dnx120.mov";
    }

print "$cmd\n";
if ($EXECUTE) {system $cmd;}
}
