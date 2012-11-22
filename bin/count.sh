#!/bin/bash

#mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
#select count(*) as total from contents;
#EOF


#mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
#select count(*) as 'duplicate_total:' from contexts group by title having count(*) > 1;
#EOF


mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
select count(*) from contents_new where createdby='wenxuecity_news.pl';
select count(*) from contents_new where createdby='wenxuecity_gossip.pl';
select count(*) from contents_new where createdby='wenxuecity_ent.pl';
select count(*) from contents_new where createdby='dwnews.pl';
select count(*) from contents_new where createdby='6park.pl';
EOF
