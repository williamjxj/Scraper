#!/bin/bash

#sql='SELECT iid, name, iurl FROM items WHERE cid =3 AND groups =2 ORDER BY iid'
sql='SELECT iid FROM items WHERE cid=3 AND groups=2 ORDER BY iid'

#CMD="mysql -u dixitruth -p'dixi123456' --database dixi -h localhost"
CMD="mysql -u root  --database dixi -h localhost"

batch="./chinafnews.pl -i "

cd $HOME/scraper/chinafnews/

echo $sql | $CMD | grep -v id | while read item_id
do
	$batch $item_id &
done

cd -
