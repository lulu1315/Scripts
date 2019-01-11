#!/bin/bash

start=200
end=200

for i in `seq $start $end`;
    do
    ii=$(printf "%04d" $i)
        echo $ii
        EDGES.pl -conf edges.conf -f $ii $ii -force
        POTRACE.pl -conf potrace.conf -f $ii $ii -force
        LINEART.pl -conf lineart.conf -f $ii $ii -force
    done 
