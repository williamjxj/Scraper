#! /bin/bash

cd $HOME/scraper

sql='SELECT iid, name, iurl FROM items WHERE cid =3 AND groups =2 ORDER BY iid'

MYSQL='/opt/lampp/bin/mysql -u dixitruth -p"dixi123456" -D dixi -h localhost'

cmd="$HOME/scraper/chinafnews.pl -c "

for i in `echo $sql | MYSQL`
do
	$cmd $i
done

cd -