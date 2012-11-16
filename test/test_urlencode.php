<?php

header('Content-Type: text/html; charset=utf-8');

$a = '王波';
$b = urlencode($a);
$c =  mb_convert_encoding($a, 'gb2312', 'utf-8');
$d = urlencode($c);

// %CD%F5%B2%A8
//[王波], [%E7%8E%8B%E6%B3%A2], [��], [%CD%F5%B2%A8
echo "[" . $a . '], [' . $b . "], [" . $c . '], [' . $d . "<br>\n";

?>
<script language="javascript">
//%E7%8E%8B%E6%B3%A2
alert(encodeURI('王波'));
</script>
