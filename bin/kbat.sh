#!/bin/bash

export PATH=.:$PATH
JOB='gk.pl'

cd $HOME/business/

$JOB -a | while read city
do
	echo "=============================="
	echo $JOB -c "$city"
	$JOB -c "$city"
done

