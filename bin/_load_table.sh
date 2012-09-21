#! /bin/bash

if [ $# -eq 0 ]; then
 echo "What step do you want to start from?" >>/tmp/merrors.log
 exit 10;
fi
if [ $# -eq 4 ]
then
	nohup /home/backup/DBs/monthly/getCSV.bash  >/dev/null 2>/tmp/merrors.log &

---------------------------------------------

MYSQL='/opt/lampp/mysql/bin/mysql'
for b in `echo "SELECT distinct file FROM monthly_records WHERE result='P'" 
	| $MYSQL --skip-column-names -u "${USER1}" -p"${PASS1}" -h localhost -D ${DB1}`

$MYSQL -u "${USER}" -p"${PASS}" -h localhost -D ${DB} <<EOF
load data local infile '$file'
 into table ${TABLE}
 fields terminated by ','
 enclosed by '"'
 escaped by '\\\'
 lines terminated by '\n';
 \q
EOF