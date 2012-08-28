#!/bin/bash
# bat.sh 1

export PATH=.:$PATH
cd $HOME/business

KEY=$2
JOB=$3
if [ $# -ne 3 ]; then
    echo "1,2,3,4,5,6,7,8 or 9?";
    exit;
fi  
    
#1,2,3,4,5,6,7,8,9,10
$JOB -a $1 | while read city
do
	echo "=============================="
	echo $JOB -c "$city" -k "$KEY"
	$JOB -c "$city" -k "$KEY"
done

