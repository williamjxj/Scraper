#!/bin/bash

DDIR='/home/williamjxj/scraper/daemons/'
cd ${DDIR}

echo "Currently status: "
ps -ef | grep perl | grep -v grep

echo "Now killing current process: "
if [ -x ./killD.sh ]; then
	./killD.sh
fi

echo "Now Restart Daemon process: "
for i in `ls *D.pl`
do
	ps -ef | grep $i | grep -v grep >/dev/null 2>&1
	if [ $? -eq 0 ]; then
		echo "$i is already running."
	else
		${DDIR}$i
		echo "$i NOW is starting running..."
	fi
done

echo "Latest status: "
ps -ef | grep perl | grep -v grep

