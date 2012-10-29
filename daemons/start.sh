#!/bin/bash

DDIR='/home/williamjxj/scraper/daemons/'
cd ${DDIR}
for i in `ls *D.pl`
do
	echo  $i
	ps -ef | grep $i | grep -v grep >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "$i is running."
	else
		${DDIR}$i
		echo "$i NOW is starting running..."
	fi
done

