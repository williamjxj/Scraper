<?php
session_start();
define('MAXLEN', 200);

// header ("content-type: text/xml; charset=utf-8");
// if(!headers_sent()) header('Content-Type: application/json; charset=utf-8', true,200);

$rss_url = 'http://news.baidu.com/n?cmd=1&class=civilnews&tn=rss';
$rawFeed = file_get_contents($rss_url);

$xml = simplexml_load_string($rawFeed);
//$xml = new SimpleXmlElement($rawFeed);

if(count($xml) == 0) return;

$ary = array();
foreach($xml->channel->item as $item) {
	$sa = array();
	$sa['title'] = (string)parse_cdata(trim($item->title));
	$sa['desc'] = parse_desc(parse_cdata(trim($item->description)));
	$sa['link'] = (string)trim($item->link);
	$sa['pubDate'] = get_datetime((string)$item->pubDate);
	$sa['author'] = (string)$item->author;
	$sa['source'] = (string)$item->source;
	
	array_push($ary, $sa);
}

//echo "<pre>"; print_r($ary); echo "</pre>";
echo json_encode($ary);
exit;


function parse_cdata($str) {
	if(preg_match("/CDATA/", $str)) {
		$str = preg_replace("/^.*CDATA[/", '', $str);
		$str = preg_replace("/]]$/", '', $str);		
	}
	return $str;
}

function parse_desc($summary) {
	if (!isset($summary) || empty($summary) || preg_match("/^\s+$/", $summary))		return '';

	// echo "\n[".$summary."]\n";
	// Create summary as a shortened body and remove images, extraneous line breaks, etc.
	$summary = preg_replace("/<img[^>]*>/i", "", $summary);
	$summary = preg_replace("/^(<br[\s]?\/>)*/i", "", $summary);
	$summary = preg_replace("/(<br[\s]?\/>)*$/i", "", $summary);
	$summary = preg_replace("/^\s+/", "", $summary);
	$summary = preg_replace("/\s+$/", "", $summary);
	
	$summary = trim($summary);
	return $summary;
}

function get_datetime($dt) {
	return date("m/d H:i",  strtotime(trim($dt)));
}
?>
