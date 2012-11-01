<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script src="http://code.jquery.com/jquery-latest.js"></script>
</head>
<body>
<a href="javacript:;" onclick="return call_pl();">Call Perl </a>
<h3>SOSO</h3><div id="soso"></div>
<h3>YAHOO</h3><div id="yahoo"></div>
<h3>BAIDU</h3><div id="baidu"></div>
<h3>GOOGLE</h3><div id="google"></div>
<form class="well form-search" action="<?=$_SERVER['PHP_SELF'];?>" method="get" name="search1">
  <input type="text" name="q" id="q" class="search-query" style="width:399px" data-provide="typeahead" autocomplete="off" placeholder="请输入关键词" />
  <button type="submit" class="btn btn-primary"><i class="icon-search icon-white"></i>搜索</button>
</form>
<script type="text/javascript">
function call_pl() {
	// work: $('#pp').load('./pp.php'); 
	$('#google').load('./fork_gg.cgi', { 'q' : $('#q').val() }, function(data) { console.log(data); });
	$('#baidu').load('./fork_baidu.cgi', { 'q' : $('#q').val() }, function(data) { console.log(data); });
	$('#yahoo').load('./fork_yahoo.cgi', { 'q' : $('#q').val() }, function(data) { console.log(data); });
	$('#soso').load('./fork_soso.cgi', { 'q' : $('#q').val() }, function(data) { console.log(data); });
	return false;
}
</script>
<?php
if(isset($_GET['qq'])) {
	session_start();
	error_reporting(E_ALL);
	define("ROOT", "../");
	require_once (ROOT . "configs/config.inc.php");
	global $config;
	
	require_once (ROOT . "locales/f0.inc.php");
	global $header;
	global $search;
	global $list;
	global $footer;
	
	require_once (ROOT . 'sClass.php');
	set_lang();
	
	try {
		$obj = new FMXW_Sphinx();
	} catch (Exception $e) {
		echo $e -> getMessage(), "line __LINE__.\n";
	}
	
	//$obj -> display($tdir1 . 'ss.tpl.html');
	if (!empty($_GET['q']))
		$obj->backend_scrape($_GET['q']);
	/*	
	$fifo = fopen('/home/williamjxj/scraper/', 'r+');
	fwrite($fifo, $search_key);
	fclose($fifo);
	*/
}
?>
</body>
</html>
