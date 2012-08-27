#!/bin/bash

mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
update contexts cx, (select mid, name from channels) ca 
set cx.chan_name=ca.name
where cx.chan_id = ca.mid;
EOF;


mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF
SELECT count(*) total, chan_id, chan_name FROM `contexts` group by chan_id
EOF;