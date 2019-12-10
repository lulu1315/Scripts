#!/usr/bin/perl

use File::Find qw(find);
use Cwd;
use Env;
use Term::ANSIColor qw(:constants);

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

sub list_dirs {
        my @dirs = @_;
        my @files;
        find({ wanted => sub { push @files, $_ } , no_chdir => 1 }, @dirs);
        return @files;
}

#defaults
$INDIR="./";
$DO8=1;
$DO16=1;
$DO32=1;
$DO64=1;
$DOCUSTOM=1;
$CUSTOM=128;
$VERBOSE=1;

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-idir dirin [$INDIR]\n";
    print "-do8  [$DO8] : do 8colors palette\n";
    print "-do16 [$DO16] : do 16colors palette\n";
    print "-do32 [$DO32] : do 32colors palette\n";
    print "-do64 [$DO64] : do 64colors palette\n";
    print "-docustom customvalue [$DOCUSTOM,$CUSTOM]\n";
	exit;
}

for ($arg=0;$arg <= $#ARGV;$arg++)
{
  if (@ARGV[$arg] eq "-idir") 
    {
    $INDIR=@ARGV[$arg+1];
    print "in dir : $INDIR\n";
    }
  if (@ARGV[$arg] eq "-do8") 
    {
    $DO8=1;
    print "do8 : $DO8\n";
    }
  if (@ARGV[$arg] eq "-do16") 
    {
    $DO16=1;
    print "do16 : $DO16\n";
    }
  if (@ARGV[$arg] eq "-do32") 
    {
    $DO32=1;
    print "do32 : $DO32\n";
    }
  if (@ARGV[$arg] eq "-do64") 
    {
    $DO64=1;
    print "do64 : $DO64\n";
    }
  if (@ARGV[$arg] eq "-docustom") 
    {
    $DOCUSTOM=1;
    $CUSTOM=@ARGV[$arg+1];
    print "docustom : $CUSTOM \n";
    }
}

$GMIC = "/shared/foss-18/gmic-2.8.0_pre/src/gmic";

my @dirs = $INDIR;
my @subdirs;
find({ wanted => sub { push @subdirs, $_ } , no_chdir => 1 }, @dirs);

foreach $subdir (sort { substr($a, 1) <=> substr($b, 1) } @subdirs) 
    { 
    if (-d "$subdir") #make sure it is a directory
        {
        print "scanning dir : $subdir\n";
        opendir SUBDIR, "$subdir";
        @images = grep { /.jpg/ || /.jpeg/ || /.png/} readdir SUBDIR;
        closedir SUBDIR;
        foreach $image (@images) 
            {
            @ima=split(/\./,$image);
            $EXT=@ima[$#ima];
            $imaroot="";
            for ($i=0;$i<$#ima;$i++) {
                $imaroot=$imaroot.@ima[$i]."_";
            }
            print "$image $imaroot $EXT \n";
            if ($DO8) {
                $sample=8;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,1 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_sorted.jpg";
                print "$cmd\n";
                system $cmd;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,2 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_importance.jpg";
                print "$cmd\n";
                system $cmd;
                }
            if ($DO16) {
                $sample=16;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,1 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_sorted.jpg";
                print "$cmd\n";
                system $cmd;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,2 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_importance.jpg";
                print "$cmd\n";
                system $cmd;
                }
            if ($DO32) {
                $sample=32;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,1 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_sorted.jpg";
                print "$cmd\n";
                system $cmd;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,2 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_importance.jpg";
                print "$cmd\n";
                system $cmd;
                }
            if ($DO64) {
                $sample=64;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,1 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_sorted.jpg";
                print "$cmd\n";
                system $cmd;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,2 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_importance.jpg";
                print "$cmd\n";
                system $cmd;
                }
            if ($DOCUSTOM) {
                $sample=$CUSTOM;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,1 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_sorted.jpg";
                print "$cmd\n";
                system $cmd;
                $cmd="$GMIC $subdir/$image -resize2dx 1500 --colormap $sample,1,2 -resize2dy[1] 64,1 -remove[0] -o $subdir/$imaroot\sample$sample\_importance.jpg";
                print "$cmd\n";
                system $cmd;
                }
            }
        }
    }
        
