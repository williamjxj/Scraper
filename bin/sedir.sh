#! /bin/bash

if [ "$#" -eq 0 ]; then
	echo "Please input dirname";
	exit 1;
fi

if [ "$#" -eq 1 ]; then
	cd $1
	for i in `ls *pl`;
	do
		sedi.sh $i;
	done
	cd -
fi
