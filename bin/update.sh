#! /bin/bash
# UPDATE `biz_us_contact` set accessible = 'N' WHERE web = 'www.altousa.net'
# UPDATE `biz_us_contact` set accessible = 'N' WHERE web = 'www.covingtonelectric.net'

cd $HOME/business

MYSQL="mysql -u biz_us -pwilliam -D business_db"

if [ $# -ne 1 ]; then
    echo "Which website to make un-accessible? ";
    exit;
fi
web=$1
sql="UPDATE biz_us_contact set accessible = 'N' WHERE web like '%$web%'";
echo $sql

# $MYSQL << $sql;
echo $sql | $MYSQL;

