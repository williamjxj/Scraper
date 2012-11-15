<?php

header('Content-Type: text/html; charset=utf-8');

$a = '王波';

$b = urlencode($a);

$c =  mb_convert_encoding($a, 'gb2312', 'utf-8');

echo "[" . $a . '], [' . $b . "], [" . $c . "]<br>\n";
?>