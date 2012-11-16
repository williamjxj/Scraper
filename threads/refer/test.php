<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script src="http://code.jquery.com/jquery-latest.js"></script>
</head>
<body>
<h3>SOSO</h3><div id="soso"></div>
<h3>YAHOO</h3><div id="yahoo"></div>
<h3>BAIDU</h3><div id="baidu"></div>
<h3>GOOGLE</h3><div id="google"></div>
<form class="well form-search" action="<?=$_SERVER['PHP_SELF'];?>" method="get" name="search1">
  <input type="text" name="q" id="q" class="search-query" style="width:399px" data-provide="typeahead" autocomplete="off" placeholder="请输入关键词" value="文学城" />
  <button type="submit" class="btn btn-primary"><i class="icon-search icon-white"></i>搜索</button>
  <button type="button" class="btn" id="search_button"><i class="icon-search icon-white"></i>查询关键词</button>
</form>
<iframe width="640" height="480" frameborder="0" allowfullscreen id="if"></iframe>
<script type="text/javascript">
$(function() {
	$('#search_button').click(function() {
		var kw = $('#q').val();
		//	$('#if').attr('src','http://www.baidu.com/s?ie=utf-8&bs='+kw+'&f=8&rsv_bp=1&rsv_spt=3&wd='+ kw +'&inputT=0');

		$.getJSON('./baidu.cgi', { 'q' : kw }, function(data) { $('#baidu').append(data); });
	$.getJSON('./google.cgi', { 'q' : kw }, function(data) {
		var ary = [];
		$.each(data, function(key, val) {
			t = '<li><a href="' + val[0] + '">' + val[1] + '</a><br>' + val[2] + '</li>';
			ary.push(t);
		});
		$('#google').append(ary);
	});
	$.getJSON('./soso.cgi', { 'q' : kw }, function(data) {
		var ary = [];
		$.each(data, function(key, val) {
			t = '<li><a href="' + val[0] + '">' + val[1] + '</a><br>' + val[2] + '</li>';
			ary.push(t);
		});
		$('#soso').append(ary);
	});
	$.getJSON('./yahoo.cgi', { 'q' : kw }, function(data) {
		var ary = [];
		$.each(data, function(key, val) {
			t = '<li><a href="' + val[0] + '">' + val[1] + '</a><br>' + val[2] + '</li>';
			ary.push(t);
		});
		$('#yahoo').append(ary);
	});
  });
});
</script>
<?php
if(isset($_GET['qq'])) {
	session_start();
	error_reporting(E_ALL);
	define("ROOT", "../fmxw/");
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
