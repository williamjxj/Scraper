#!/bin/bash

mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF


show variables like 'character_set_%';

select count(*) as 'total contexts' from contexts;

select count(*) as 'total contents' from contents;

select count(*) as 'total channels' from channels;

EOF
