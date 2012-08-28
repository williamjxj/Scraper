#! /bin/bash
# UPDATE `biz_us_contact` set accessible = 'N' WHERE web = 'www.altousa.net'
# UPDATE `biz_us_contact` set accessible = 'N' WHERE web = 'www.covingtonelectric.net'

MYSQL="mysql -u biz_us -pwilliam -D business_db"

if [ $# -ne 1 ]; then
    echo "1,2,3,4,5,6 or 7?";
    exit;
fi

cd $HOME/business

if [ "$1" = '1' ];then
$MYSQL <<"EOT"
	select email1, web from biz_us_contact where (web is not null and trim(web) != '') and (email1 is not null and email1!='');
EOT
fi

# 359
if [ "$1" = '2' ];then
$MYSQL <<"EOT"
	select name, category,  website, concat(county,',',city,',',state) location  from biz_us where name like 'martial art%' and website!='';
EOT
fi

if [ "$1" = '3' ];then
$MYSQL <<"EOT"
	select concat(county,',',city,',',state) location from biz_us where website != '' limit 0,30;
EOT
fi

if [ "$1" = '4' ];then
$MYSQL <<"EOT"
	select concat(email, ', ', category, ', ', name) from biz_us_contact where (email is not null and email!='');
	#select concat(email, ', ', email1, ', ', category, ', ', name) from biz_us_contact where email is not null;
EOT
fi

if [ "$1" = '5' ];then
$MYSQL <<"EOT"
	select count(*) from biz_us_contact where email!='';
	select count(*) from biz_us_contact where email is not null;
	select count(*) from biz_us_contact where (email is not null and email!='');
EOT
fi

if [ "$1" = '6' ];then
$MYSQL <<"EOT"
	select web from biz_us_contact where  accessible = 'N';
EOT
fi

