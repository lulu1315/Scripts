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
$INDIR="./originales";
$OUTDIR="./";
$ZEROPAD=4;
$EXT="png";
$FPS=25;
$FORMAT="ffmpeg_prores";
$PRORESCODEC="-c:v prores_ks -profile:v 3";
$H264CODEC="-c:v libx264 -crf 10 -pix_fmt yuv420p";
$H264CODEC="-c:v libx264 -crf 10";
$EXECUTE=0;
$VERBOSE=1;

if ($#ARGV == -1) {
	print "usage: $scriptname.pl \n";
	print "-idir dirin [$INDIR]\n";
	print "-odir dirout [$OUTDIR]\n";
	print "-ext image extension [$EXT]\n";
	print "-rate fps [$FPS]\n";
	print "-zeropad [$ZEROPAD]\n";
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
  if (@ARGV[$arg] eq "-rate") 
    {
    $FPS=@ARGV[$arg+1];
    print "frame per second : $FPS\n";
    }
  if (@ARGV[$arg] eq "-format") 
    {
    $FORMAT=@ARGV[$arg+1];
    print "output format : $FORMAT\n";
    }
  if (@ARGV[$arg] eq "-zeropad") 
    {
    $ZEROPAD=@ARGV[$arg+1];
    print "zeropad $ZEROPAD ...\n";
    }
  if (@ARGV[$arg] eq "-exec") 
    {
    $EXECUTE=1;
    print "execute command\n";
    }
}

if ($EXT eq "exr") {$GAMMA = "-gamma 2.2";} else {$GAMMA = "";}

my @dirs = $INDIR;
my @shots;
find({ wanted => sub { push @shots, $_ } , no_chdir => 1 }, @dirs);

foreach $shot (sort { substr($a, 1) <=> substr($b, 1) } @shots) 
    { 
    if ((-d "$shot") && (index($shot, "snaps") == -1)) #make sure it is a directory
        {
        print "scanning shot : $shot\n";
        opendir SHOT, "$shot";
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
                unless ($seen{$imaroot}) 
                    {
                    #print ("    unique :  $imaroot\n");
                    $seen{$imaroot} = 1;
                    push(@uniq, $imaroot);
                    }
                }
            }
            foreach $root (@uniq) 
                {
                #print "     --> root : $root\n";
                #reread image seq
                opendir SHOT, "$shot";
                @images = grep { /$root/ } readdir SHOT;
                closedir SHOT;
                $min=9999999;
                $max=-1;
                foreach $image (@images) 
                    { 
                    #print ("$ima\n");
                    @tmp=split(/\./,$image);
                    if ($#tmp >= 2 && @tmp[$#tmp] eq $EXT)
                        {
                        #print("image : $image @tmp[$#tmp]\n");
                        $numframe=int($tmp[$#tmp-1]);
                        #print ("$numframe\n");
                        if ($numframe > $max) {$max = $numframe;}
                        if ($numframe < $min) {$min = $numframe;}
                        #print ("min/max : $min $max\n");
                        }
                    }
                $sshot=$shot;
                $sshot=~ s/\.\///g;
                $sshot=~ s/\//_/g;
                if ($FORMAT eq "csv")
                    {
                    if ($max == $min)
                        {
                        print BOLD RED "$shot,$root,\%0$ZEROPAD\d,$EXT,$min,$max\n";print RESET;
                        }
                    else
                        {
                        print ("$shot,$root,\%0$ZEROPAD\d,$EXT,$min,$max\n");
                        }
                    }
                if ($FORMAT eq "ffmpeg_prores")
                {
                if ($max == $min)
                    {print BOLD RED "only one frame ... skipping\n";print RESET;}
                else
                    {
                    $cmd = "ffmpeg -start_number $min -r $FPS $GAMMA -i $shot/$root.\%0$ZEROPAD\d.$EXT $PRORESCODEC $OUTDIR/$sshot\_$root.mov";
                    #$cmd = "ffmpeg -start_number $min -r $FPS $GAMMA -i $shot/$root.%04d.$EXT $PRORESCODEC $OUTDIR/$sshot.mov";
                    print ("$cmd\n");
                    if ($EXECUTE) {system ($cmd);}
                    }
                }
                if ($FORMAT eq "ffmpeg_h264")
                {
                if ($max == $min)
                    {print BOLD RED "only one frame ... skipping\n";print RESET;}
                else
                    {
                    $cmd = "ffmpeg -start_number $min -r $FPS $GAMMA -i $shot/$root.\%0$ZEROPAD\d.$EXT $H264CODEC $OUTDIR/$sshot\_$root.mov";
                    #$cmd = "ffmpeg -start_number $min -r $FPS $GAMMA -i $shot/$root.%04d.$EXT $PRORESCODEC $OUTDIR/$sshot.mov";
                    print ("$cmd\n");
                    if ($EXECUTE) {system ($cmd);}
                    }
                }
            }
        }
    }
