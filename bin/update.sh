#! /bin/bash

if [ $# -eq 0 ]; then
 echo "What step do you want to start from?"
 exit 10;
fi

cd $HOME/scraper

sql='SELECT iid, name, iurl FROM items WHERE cid =3 AND groups =2 ORDER BY iid'

MYSQL='mysql -u dixitruth -p"dixi123456" -D dixi -h localhost'

cmd="$HOME/scraper/chinafnews.pl -i "

for i in `echo $sql | MYSQL`
do
	$cmd $i
done

cd -
