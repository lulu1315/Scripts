#!/usr/bin/perl

use Cwd;
use Env;
use Term::ANSIColor qw(:constants);
use Image::Magick;
#http://www.imagemagick.org/script/command-line-options.php
use List::Util qw(min max);
$script = $0;
print BOLD BLUE "script : $script\n";print RESET;
@tmp=split(/\//,$script);
$scriptname=$tmp[$#tmp];
$CWD=getcwd;
#get project name
@tmp=split(/\//,$CWD);
$PROJECT=$tmp[$#tmp];
print BOLD BLUE "project : $PROJECT\n";print RESET;

#pour keyframe
$counter=1;
$keycount=0;
#
$FSTART=1;
$FEND=10;
$VAR=33;

for ($i = $FSTART ;$i <= $FEND;$i=$i+$counter)
    {
    #pour keyframe
    if (-e "keyframe.conf.key")
        {
        require "keyframe.conf.key";
        ${$KEYNAME}=keyframe($KEYSAFE);
        $counter=0; #if -e $CONF.key
        $keycount++;
        if ($keycount > $KEYFRAME) {last;}
        }
    #
    print "processing $i\n";
    print "keycount $keycount\n";
    print "VAR=$VAR\n";
    }
    
# gestion des keyframes
sub keyframe {
    @keyvals = split(/,/,$_[0]);
    #print "keyvals = @keyvals\n";
    $key1=$keyvals[0];
    $key2=$keyvals[1];
    return $key1+$keycount*(($key2-$key1)/($KEYFRAME-1));
    }
