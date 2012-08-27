<?php

$host = 'localhost';
$user = 'dixitruth';
$pwd = 'dixi123456';
$db = 'dixi';

$link = mysql_connect($host, $user, $pwd);

mysql_select_db($db);

if( mysql_error() ) { print "Database ERROR: " . mysql_error(); }

mysql_query("SET NAMES 'utf8'", $link);

$sql = "select * from admin_users";
$res = mysql_query($sql);
echo "<ul>\n";
while ($row = mysql_fetch_assoc($res)) {
	echo "<li>";
	foreach($row as $v) echo htmlspecialchars($v) . "\t";
	echo "</li>\n"; 
}
echo "</ul>\n";
