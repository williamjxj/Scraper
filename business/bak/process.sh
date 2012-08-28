#! /bin/bash

if [ $# -ne 1 ]; then
    echo "1,2?";
    exit;
fi

cd $HOME/business

if [ "$1" = '1' ];then
for ((;;))
do
	./contact.pl
done
fi

if [ "$1" = '2' ];then
for ((;;))
do
	./cc.pl
done
fi

