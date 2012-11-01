#!/bin/bash

if [ "$#" -eq 0 ]; then
	echo "Please input filename";
	exit 1;
fi

if [ "$#" -eq 1 ]; then
	#sed -i 's/{ctrl-v}{ctrl-m}//g' fpull
	sed -i 's///g' $1
	echo "Done for $1."
fi

