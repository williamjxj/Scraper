<?php

header('Content-Type: text/html; charset=utf-8');

$a = '王波';

$b = urlencode($a);

$c =  mb_convert_encoding($a, 'utf-8', 'gb2312');

echo "[" . $a . '], [' . $b . "], [" . $c . "]<br>\n";
?>