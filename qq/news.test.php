<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<script src="http://code.jquery.com/jquery-latest.js"></script>
</head>
<body>
<h3>SOSO</h3>
<div id="soso"></div>
<form class="well form-search" action="scraper/qq/news.soso.pl" method="get">
  <input type="text" name="q" id="q" class="search-query" style="width:399px" data-provide="typeahead" autocomplete="off" placeholder="请输入关键词" value="文学城" />
  <button type="submit" class="btn btn-primary"><i class="icon-search icon-white"></i>搜索</button>
</form>
<script type="text/javascript">
$(function() {
	$(form).click(function() {
		var kw = $('#q').val();
		alert(kw);
		$('#soso').load($(this).attr('action'), {q: kw}, function(data) {
		});
	});
});
</script>
