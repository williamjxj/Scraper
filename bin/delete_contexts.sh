#!/bin/bash

mysql -u dixitruth -p"dixi123456" -D dixi -h localhost <<EOF

delete from contents;

EOF
