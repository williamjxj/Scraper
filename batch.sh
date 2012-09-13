#!/bin/bash

cd $HOME/scraper

#sql='SELECT iid, name, iurl FROM items WHERE cid =3 AND groups =2 ORDER BY iid'
sql='SELECT iid FROM items WHERE cid =3 AND groups =2 ORDER BY iid'

#CMD="/opt/lampp/bin/mysql -u dixitruth -p'dixi123456' --database dixi -h localhost"
CMD="/opt/lampp/bin/mysql -u root  --database dixi -h localhost"

batch="$HOME/scraper/chinafnews.pl -i "

echo $sql | $CMD | grep -v id | while read item_id
do
	$batch $item_id &
done

cd -
