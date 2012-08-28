#!/bin/bash
# bat.sh 1

export PATH=.:$PATH

cd $HOME/business

JOB='./google.pl'

if [ $# -ne 1 ]; then
    echo "1,2,3,4,5,6,7,8 or 9?";
    exit;
fi  
    
#1,2,3,4,5,6,7,8,9
$JOB -a $1 | while read city
do
	echo "=============================="
	echo $JOB -c "$city" -k "marketing firm"
	$JOB -c "$city" -k "marketing firm"
done

