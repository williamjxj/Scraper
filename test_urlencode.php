<?php

header('Content-Type: text/html; charset=utf-8');

$a = '王波';

$b = urlencode($a);

echo "[" . $a . '], [' . $b . "]<br>\n";
?>