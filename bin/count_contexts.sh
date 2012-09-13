#!/bin/bash

mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
select count(*) as total from contexts;

EOF


mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
select count(*) as 'duplicate_total:' from contexts group by linkname having count(*) > 1;

EOF
