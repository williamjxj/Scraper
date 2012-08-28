#!/bin/bash

export PATH=.:$PATH
JOB='google.pl'

cd $HOME/business/

#if [ $# -ne 1 ]; then
#    echo "Which city to download ?"
#	exit;
#fi
#if [ "$1" = '1' ];then
#	jobs='jobs'
#fi

# usc,usk,cac,cak
# $JOB -a cac | while read city
$JOB -a usk | while read city
do
	echo $JOB -c "$city"
	$JOB -c "$city"
done

