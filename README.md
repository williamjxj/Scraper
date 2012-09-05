Scraper
=======

scraper for dixitruth

#!/usr/bin/perl
#!/opt/lampp/bin/perl

use sudo /opt/lampp/bin/cpan to install feature, DateTime etc.


$MYSQL -u "${USER}" -p"${PASS}" -h localhost -D ${DB} <<EOF
    update monthly_notice set enable_process = 'Y' WHERE enable_process='N';
EOF


echo "The monthly data upload processing [ $param ] is done at `date '+%F %T'`." | /bin/mail -s "Data
monthly upload processing is done." williamjxj@hotmail.com


SET character_set_client = x;
SET character_set_results = x;
SET character_set_connection = x;


use constant NEWS = qq(
	hot, guonei, guoji, fangtan, jiankang, qiye, puguangtai, shendu, fagui, fiance, baogao
);

select mid, name from channels order by mid
select iid, name from items order by iid

insert into items(iurl, name, weight, groups, description, category, cid) 
select url, name, weight, groups, description, cname, cid from channels

update channels set groups=4 where groups=1;
update channels set groups=5 where groups=2;
update channels set cid=3;


ALTER TABLE categories CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE items CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE channels CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE tags CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;
ALTER TABLE lookups CONVERT TO CHARACTER SET utf8 COLLATE utf8_general_ci;

update contents ct, (select iid, name from items) it
 set ct.iid=it.iid
where it.name=ct.item

SELECT * FROM foo WHERE id>4 ORDER BY id LIMIT 1