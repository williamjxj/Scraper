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
