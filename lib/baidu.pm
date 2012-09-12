package baidu;

# http://news.baidu.com/newscode.html
use config;
use common;
@ISA = qw(common);
use strict;
use Data::Dumper;
our ( $sth );

# 不然$category和$item 为乱码.
use utf8;
use encoding 'utf8';

use constant CONTACTS => q{contexts};

#http://top.baidu.com/rss.php
our @ranks = (
	[ '实时热点排行榜', 'http://top.baidu.com/rss_xml.php?p=top10', '新闻' ],
	[ '七日关注排行榜', 'http://top.baidu.com/rss_xml.php?p=weekhotspot', '事件' ],
	[ '今日热门搜索排行榜', 'http://top.baidu.com/rss_xml.php?p=top_keyword', '事件' ],
	[ '世说新词排行榜', 'http://top.baidu.com/rss_xml.php?p=shishuoxinci', '事件' ],
	[ '最近事件排行榜', 'http://top.baidu.com/rss_xml.php?p=shijian', '事件' ],
	[ '上周事件排行榜', 'http://top.baidu.com/rss_xml.php?p=shijian_lastweek', '事件' ],
	[ '上月事件排行榜', 'http://top.baidu.com/rss_xml.php?p=shijian_lastmonth', '事件' ],
	[ '今日热点人物排行榜', 'http://top.baidu.com/rss_xml.php?p=hotman', '人物' ],
	[ '今日美女排行榜', 'http://top.baidu.com/rss_xml.php?p=girls', '人物' ],
	[ '今日帅哥排行榜', 'http://top.baidu.com/rss_xml.php?p=boys', '人物' ],
	[ '今日女演员排行榜', 'http://top.baidu.com/rss_xml.php?p=FStar', '明星' ],
	[ '今日男演员排行榜', 'http://top.baidu.com/rss_xml.php?p=MStar', '明星' ],
	[ '今日女歌手排行榜', 'http://top.baidu.com/rss_xml.php?p=ygeshou', '明星' ],
	[ '今日男歌手排行榜', 'http://top.baidu.com/rss_xml.php?p=ngeshou', '明星' ],
	[ '今日体坛人物排行榜', 'http://top.baidu.com/rss_xml.php?p=titan', '明星' ],
	[ '今日互联网人物排行榜', 'http://top.baidu.com/rss_xml.php?p=internet', '明星' ],
	[ '今日名家人物排行榜', 'http://top.baidu.com/rss_xml.php?p=mingjia', '明星' ],
	[ '今日财经人物排行榜', 'http://top.baidu.com/rss_xml.php?p=caijing', '明星' ],
	[ '今日富豪排行榜', 'http://top.baidu.com/rss_xml.php?p=rich', '人物' ],
	[ '今日政坛人物排行榜', 'http://top.baidu.com/rss_xml.php?p=zhengtan', '人物' ],
	[ '今日历史人物排行榜', 'http://top.baidu.com/rss_xml.php?p=lishiren', '人物' ],
	[ '今日人物关系排行榜', 'http://top.baidu.com/rss_xml.php?p=relation', '人物' ],
	[ '今日慈善组织排行榜', 'http://top.baidu.com/rss_xml.php?p=cishan', '公益' ],
	[ '今日房产企业排行榜', 'http://top.baidu.com/rss_xml.php?p=fangchanqy', '房地产' ],
);

our @focus = (
	[ '国内焦点', "http://news.baidu.com/n?cmd=1&class=civilnews&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '台湾焦点', "http://news.baidu.com/n?cmd=1&class=taiwan&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '港澳焦点', "http://news.baidu.com/n?cmd=1&class=gangaotai&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '国际焦点', "http://news.baidu.com/n?cmd=1&class=internews&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '环球视野焦点', "http://news.baidu.com/n?cmd=1&class=hqsy&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '国际人物焦点', "http://news.baidu.com/n?cmd=1&class=renwu&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '军事焦点', "http://news.baidu.com/n?cmd=1&class=mil&tn=rss", '军事', 23, '军事', 46 ],
	[ '中国军情焦点', "http://news.baidu.com/n?cmd=1&class=zhongguojq&tn=rss", '军事', 23, '军事', 46 ],
	[ '台海聚焦焦点', "http://news.baidu.com/n?cmd=1&class=taihaijj&tn=rss", '军事', 23, '军事', 46 ],
	[ '国际军情焦点', "http://news.baidu.com/n?cmd=1&class=guojijq&tn=rss", '军事', 23, '军事', 46 ],
	[ '财经焦点', "http://news.baidu.com/n?cmd=1&class=finannews&tn=rss", '财经', 2, '财经', 43 ],
	[ '股票焦点', "http://news.baidu.com/n?cmd=1&class=stock&tn=rss", '财经', 2, '财经', 43 ],
	[ '理财焦点', "http://news.baidu.com/n?cmd=1&class=money&tn=rss", '财经', 2, '财经', 43 ],
	[ '宏观经济焦点', "http://news.baidu.com/n?cmd=1&class=hongguan&tn=rss", '财经', 2, '财经', 43 ],
	[ '产业经济焦点', "http://news.baidu.com/n?cmd=1&class=chanye&tn=rss", '财经', 2, '财经', 43 ],
	[ '互联网焦点', "http://news.baidu.com/n?cmd=1&class=internet&tn=rss", '科技', 7, '科技', 40 ],
	[ '人物动态焦点', "http://news.baidu.com/n?cmd=1&class=rwdt&tn=rss", '科技', 7, '科技', 40 ],
	[ '公司动态焦点', "http://news.baidu.com/n?cmd=1&class=gsdt&tn=rss", '科技', 7, '科技', 40 ],
	[ '搜索引擎焦点', "http://news.baidu.com/n?cmd=1&class=search_engine&tn=rss", '科技', 7, '科技', 40 ],
	[ '电子商务焦点', "http://news.baidu.com/n?cmd=1&class=e_commerce&tn=rss", '科技', 7, '科技', 40 ],
	[ '网络游戏焦点', "http://news.baidu.com/n?cmd=1&class=online_game&tn=rss", '科技', 7, '科技', 40 ],
	[ '房产焦点', "http://news.baidu.com/n?cmd=1&class=housenews&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '各地动态焦点', "http://news.baidu.com/n?cmd=1&class=gddt&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '政策风向焦点', "http://news.baidu.com/n?cmd=1&class=zcfx&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '市场走势焦点', "http://news.baidu.com/n?cmd=1&class=shichangzoushi&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '家居焦点', "http://news.baidu.com/n?cmd=1&class=fitment&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '汽车焦点', "http://news.baidu.com/n?cmd=1&class=autonews&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '新车焦点', "http://news.baidu.com/n?cmd=1&class=autobuy&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '导购焦点', "http://news.baidu.com/n?cmd=1&class=daogou&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '各地行情焦点', "http://news.baidu.com/n?cmd=1&class=hangqing&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '维修养护焦点', "http://news.baidu.com/n?cmd=1&class=weixiu&tn=rss", '体育', 8, '体育', 39 ],
	[ '体育焦点', "http://news.baidu.com/n?cmd=1&class=sportnews&tn=rss", '体育', 8, '体育', 39 ],
	[ 'NBA焦点', "http://news.baidu.com/n?cmd=1&class=nba&tn=rss", '体育', 8, '体育', 39 ],
	[ '国际足球焦点', "http://news.baidu.com/n?cmd=1&class=worldsoccer&tn=rss", '体育', 8, '体育', 39 ],
	[ '国内足球焦点', "http://news.baidu.com/n?cmd=1&class=chinasoccer&tn=rss", '体育', 8, '体育', 39 ],
	[ 'CBA焦点', "http://news.baidu.com/n?cmd=1&class=cba&tn=rss", '体育', 8, '体育', 39 ],
	[ '综合体育焦点', "http://news.baidu.com/n?cmd=1&class=othersports&tn=rss", '体育', 8, '体育', 39 ],
	[ '娱乐焦点', "http://news.baidu.com/n?cmd=1&class=enternews&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '明星焦点', "http://news.baidu.com/n?cmd=1&class=star&tn=rss", '明星', 15, '明星', 44 ],
	[ '电影焦点', "http://news.baidu.com/n?cmd=1&class=film&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '电视焦点', "http://news.baidu.com/n?cmd=1&class=tv&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '音乐焦点', "http://news.baidu.com/n?cmd=1&class=music&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '综艺焦点', "http://news.baidu.com/n?cmd=1&class=zongyi&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '演出焦点', "http://news.baidu.com/n?cmd=1&class=yanchu&tn=rss", '明星', 15, '明星', 44 ],
	[ '奖项焦点', "http://news.baidu.com/n?cmd=1&class=jiangxiang&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '游戏焦点', "http://news.baidu.com/n?cmd=1&class=gamenews&tn=rss", '研究', 18, '研究', 45 ],
	[ '网络游戏焦点', "http://news.baidu.com/n?cmd=1&class=netgames&tn=rss", '研究', 18, '研究', 45 ],
	[ '电视游戏焦点', "http://news.baidu.com/n?cmd=1&class=tvgames&tn=rss", '研究', 18, '研究', 45 ],
	[ '电子竞技焦点', "http://news.baidu.com/n?cmd=1&class=dianzijingji&tn=rss", '研究', 18, '研究', 45 ],
	[ '热门游戏焦点', "http://news.baidu.com/n?cmd=1&class=remenyouxi&tn=rss", '研究', 18, '研究', 45 ],
	[ '魔兽世界焦点', "http://news.baidu.com/n?cmd=1&class=WOW&tn=rss", '研究', 18, '研究', 45 ],
	[ '教育焦点', "http://news.baidu.com/n?cmd=1&class=edunews&tn=rss", '教育', 6, '教育', 41 ],
	[ '考试焦点', "http://news.baidu.com/n?cmd=1&class=exams&tn=rss", '教育', 6, '教育', 41 ],
	[ '留学焦点', "http://news.baidu.com/n?cmd=1&class=abroad&tn=rss", '教育', 6, '教育', 41 ],
	[ '就业焦点', "http://news.baidu.com/n?cmd=1&class=jiuye&tn=rss", '教育', 6, '教育', 41 ],
	[ '女人焦点', "http://news.baidu.com/n?cmd=1&class=healthnews&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '潮流服饰焦点', "http://news.baidu.com/n?cmd=1&class=chaoliufs&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '美容护肤焦点', "http://news.baidu.com/n?cmd=1&class=meironghf&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '减肥健身焦点', "http://news.baidu.com/n?cmd=1&class=jianfei&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '情感两性焦点', "http://news.baidu.com/n?cmd=1&class=qinggan&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '健康养生焦点', "http://news.baidu.com/n?cmd=1&class=jiankang&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '科技焦点', "http://news.baidu.com/n?cmd=1&class=technnews&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '手机焦点', "http://news.baidu.com/n?cmd=1&class=cell&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '数码焦点', "http://news.baidu.com/n?cmd=1&class=digital&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '电脑焦点', "http://news.baidu.com/n?cmd=1&class=computer&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '科普焦点', "http://news.baidu.com/n?cmd=1&class=discovery&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '社会焦点', "http://news.baidu.com/n?cmd=1&class=socianews&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '社会与法焦点', "http://news.baidu.com/n?cmd=1&class=shyf&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '社会万象焦点', "http://news.baidu.com/n?cmd=1&class=shwx&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '真情时刻焦点', "http://news.baidu.com/n?cmd=1&class=zqsk&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '奇闻异事焦点', "http://news.baidu.com/n?cmd=1&class=qwys&tn=rss", '社会', 10, '每日推荐', 33 ],
);

our @latest = (	
	[ '国内最新', "http://news.baidu.com/n?cmd=4&class=civilnews&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '时政要闻最新', "http://news.baidu.com/n?cmd=4&class=shizheng&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '高层动态最新', "http://news.baidu.com/n?cmd=4&class=gaoceng&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '人事任免最新', "http://news.baidu.com/n?cmd=4&class=gaoceng&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '台湾最新', "http://news.baidu.com/n?cmd=4&class=taiwan&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '历史档案最新', "http://news.baidu.com/n?cmd=4&class=lishi&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '台湾民生最新', "http://news.baidu.com/n?cmd=4&class=twms&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '港澳最新', "http://news.baidu.com/n?cmd=4&class=twms&tn=rss", '国内', 16, '国内动态', 21 ],
	[ '国际最新', "http://news.baidu.com/n?cmd=4&class=internews&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '环球视野最新', "http://news.baidu.com/n?cmd=4&class=hqsy&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '国际人物最新', "http://news.baidu.com/n?cmd=4&class=renwu&tn=rss", '国际', 20, '国际动态', 24 ],
	[ '军事最新', "http://news.baidu.com/n?cmd=4&class=mil&tn=rss", '军事', 23, '军事', 46 ],
	[ '中国军情最新', "http://news.baidu.com/n?cmd=4&class=zhongguojq&tn=rss", '军事', 23, '军事', 46 ],
	[ '台海聚焦最新', "http://news.baidu.com/n?cmd=4&class=taihaijj&tn=rss", '军事', 23, '军事', 46 ],
	[ '国际军情最新', "http://news.baidu.com/n?cmd=4&class=guojijq&tn=rss", '军事', 23, '军事', 46 ],
	[ '财经最新', "http://news.baidu.com/n?cmd=4&class=finannews&tn=rss", '财经', 2, '财经', 43 ],
	[ '股票最新', "http://news.baidu.com/n?cmd=4&class=stock&tn=rss", '财经', 2, '财经', 43 ],
	[ '大盘最新', "http://news.baidu.com/n?cmd=4&class=dapan&tn=rss", '财经', 2, '财经', 43 ],
	[ '个股最新', "http://news.baidu.com/n?cmd=4&class=gegu&tn=rss", '财经', 2, '财经', 43 ],
	[ '新股最新', "http://news.baidu.com/n?cmd=4&class=xingu&tn=rss", '财经', 2, '财经', 43 ],
	[ '权证最新', "http://news.baidu.com/n?cmd=4&class=warrant&tn=rss", '财经', 2, '财经', 43 ],
	[ '理财最新', "http://news.baidu.com/n?cmd=4&class=money&tn=rss", '财经', 2, '财经', 43 ],
	[ '基金最新', "http://news.baidu.com/n?cmd=4&class=fund&tn=rss", '财经', 2, '财经', 43 ],
	[ '银行最新', "http://news.baidu.com/n?cmd=4&class=bank&tn=rss", '财经', 2, '财经', 43 ],
	[ '贵金属最新', "http://news.baidu.com/n?cmd=4&class=nmetal&tn=rss", '财经', 2, '财经', 43 ],
	[ '保险最新', "http://news.baidu.com/n?cmd=4&class=insurance&tn=rss", '财经', 2, '财经', 43 ],
	[ '外汇最新', "http://news.baidu.com/n?cmd=4&class=forex&tn=rss", '财经', 2, '财经', 43 ],
	[ '期货最新', "http://news.baidu.com/n?cmd=4&class=futures&tn=rss", '财经', 2, '财经', 43 ],
	[ '宏观经济最新', "http://news.baidu.com/n?cmd=4&class=hongguan&tn=rss", '财经', 2, '财经', 43 ],
	[ '国内最新', "http://news.baidu.com/n?cmd=4&class=hg_guonei&tn=rss", '财经', 2, '财经', 43 ],
	[ '国际最新', "http://news.baidu.com/n?cmd=4&class=hg_guoji&tn=rss", '财经', 2, '财经', 43 ],
	[ '产业经济最新', "http://news.baidu.com/n?cmd=4&class=chanye&tn=rss", '财经', 2, '财经', 43 ],
	[ '互联网最新', "http://news.baidu.com/n?cmd=4&class=internet&tn=rss", '科技', 7, '科技', 40 ],
	[ '人物动态最新', "http://news.baidu.com/n?cmd=4&class=rwdt&tn=rss", '科技', 7, '科技', 40 ],
	[ '公司动态最新', "http://news.baidu.com/n?cmd=4&class=gsdt&tn=rss", '科技', 7, '科技', 40 ],
	[ '搜索引擎最新', "http://news.baidu.com/n?cmd=4&class=search_engine&tn=rss", '科技', 7, '科技', 40 ],
	[ '电子商务最新', "http://news.baidu.com/n?cmd=4&class=e_commerce&tn=rss", '科技', 7, '科技', 40 ],
	[ '网络游戏最新', "http://news.baidu.com/n?cmd=4&class=online_game&tn=rss", '科技', 7, '科技', 40 ],
	[ '房产最新', "http://news.baidu.com/n?cmd=4&class=housenews&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '各地动态最新', "http://news.baidu.com/n?cmd=4&class=gddt&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '政策风向最新', "http://news.baidu.com/n?cmd=4&class=zcfx&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '市场走势最新', "http://news.baidu.com/n?cmd=4&class=shichangzoushi&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '家居最新', "http://news.baidu.com/n?cmd=4&class=fitment&tn=rss", '房地产', 13, '房地产', 37 ],
	[ '汽车最新', "http://news.baidu.com/n?cmd=4&class=autonews&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '新车最新', "http://news.baidu.com/n?cmd=4&class=autobuy&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '导购最新', "http://news.baidu.com/n?cmd=4&class=daogou&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '各地行情最新', "http://news.baidu.com/n?cmd=4&class=hangqing&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '维修养护最新', "http://news.baidu.com/n?cmd=4&class=weixiu&tn=rss", '汽车', 24, '汽车', 47 ],
	[ '体育最新', "http://news.baidu.com/n?cmd=4&class=sportnews&tn=rss", '体育', 8, '体育', 39 ],
	[ 'NBA最新', "http://news.baidu.com/n?cmd=4&class=nba&tn=rss", '体育', 8, '体育', 39 ],
	[ '姚明-火箭最新', "http://news.baidu.com/n?cmd=4&class=yaoming&tn=rss", '体育', 8, '体育', 39 ],
	[ '易建联-篮网最新', "http://news.baidu.com/n?cmd=4&class=yijianlian&tn=rss", '体育', 8, '体育', 39 ],
	[ '国际足球最新', "http://news.baidu.com/n?cmd=4&class=worldsoccer&tn=rss", '体育', 8, '体育', 39 ],
	[ '英超最新', "http://news.baidu.com/n?cmd=4&class=Yingchao&tn=rss", '体育', 8, '体育', 39 ],
	[ '意甲最新', "http://news.baidu.com/n?cmd=4&class=Yijia&tn=rss", '体育', 8, '体育', 39 ],
	[ '西甲最新', "http://news.baidu.com/n?cmd=4&class=Xijia&tn=rss", '体育', 8, '体育', 39 ],
	[ '足球明星最新', "http://news.baidu.com/n?cmd=4&class=Zq_star&tn=rss", '体育', 8, '体育', 39 ],
	[ '曼联最新', "http://news.baidu.com/n?cmd=4&class=Manutd&tn=rss", '体育', 8, '体育', 39 ],
	[ '阿森纳最新', "http://news.baidu.com/n?cmd=4&class=Arsenal&tn=rss", '体育', 8, '体育', 39 ],
	[ '切尔西最新', "http://news.baidu.com/n?cmd=4&class=Chelsea&tn=rss", '体育', 8, '体育', 39 ],
	[ '利物浦最新', "http://news.baidu.com/n?cmd=4&class=Liverpool&tn=rss", '体育', 8, '体育', 39 ],
	[ 'AC米兰最新', "http://news.baidu.com/n?cmd=4&class=ACMilan&tn=rss", '体育', 8, '体育', 39 ],
	[ '国际米兰最新', "http://news.baidu.com/n?cmd=4&class=InterMilan&tn=rss", '体育', 8, '体育', 39 ],
	[ '尤文图斯最新', "http://news.baidu.com/n?cmd=4&class=Juventus&tn=rss", '体育', 8, '体育', 39 ],
	[ '皇马最新', "http://news.baidu.com/n?cmd=4&class=RealMadrid&tn=rss", '体育', 8, '体育', 39 ],
	[ '巴塞罗那最新', "http://news.baidu.com/n?cmd=4&class=Barcelona&tn=rss", '体育', 8, '体育', 39 ],
	[ '拜仁最新', "http://news.baidu.com/n?cmd=4&class=Bayen&tn=rss", '体育', 8, '体育', 39 ],
	[ '国内足球最新', "http://news.baidu.com/n?cmd=4&class=chinasoccer&tn=rss", '体育', 8, '体育', 39 ],
	[ '男足最新', "http://news.baidu.com/n?cmd=4&class=nanzu&tn=rss", '体育', 8, '体育', 39 ],
	[ '女足最新', "http://news.baidu.com/n?cmd=4&class=nvzu&tn=rss", '体育', 8, '体育', 39 ],
	[ '中超最新', "http://news.baidu.com/n?cmd=4&class=zhongchao&tn=rss", '体育', 8, '体育', 39 ],
	[ '球迷最新', "http://news.baidu.com/n?cmd=4&class=cn_qiumi&tn=rss", '体育', 8, '体育', 39 ],
	[ 'CBA最新', "http://news.baidu.com/n?cmd=4&class=cba&tn=rss", '体育', 8, '体育', 39 ],
	[ '赛事最新', "http://news.baidu.com/n?cmd=4&class=cba_match&tn=rss", '体育', 8, '体育', 39 ],
	[ '综合体育最新', "http://news.baidu.com/n?cmd=4&class=othersports&tn=rss", '体育', 8, '体育', 39 ],
	[ '排球最新', "http://news.baidu.com/n?cmd=4&class=volleyball&tn=rss", '体育', 8, '体育', 39 ],
	[ '乒乓球最新', "http://news.baidu.com/n?cmd=4&class=table-tennis&tn=rss", '体育', 8, '体育', 39 ],
	[ '羽毛球最新', "http://news.baidu.com/n?cmd=4&class=badminton&tn=rss", '体育', 8, '体育', 39 ],
	[ '田径最新', "http://news.baidu.com/n?cmd=4&class=Athletics&tn=rss", '体育', 8, '体育', 39 ],
	[ '游泳最新', "http://news.baidu.com/n?cmd=4&class=swimming&tn=rss", '体育', 8, '体育', 39 ],
	[ '体操最新' =>"http://news.baidu.com/n?cmd=4&class=Gymnastics&tn=rss", '体育', 8, '体育', 39 ],
	[ '网球最新', "http://news.baidu.com/n?cmd=4&class=volleyball&tn=rss", '体育', 8, '体育', 39 ],
	[ '赛车最新', "http://news.baidu.com/n?cmd=4&class=F1&tn=rss", '体育', 8, '体育', 39 ],
	[ '拳击最新', "http://news.baidu.com/n?cmd=4&class=boxing&tn=rss", '体育', 8, '体育', 39 ],
	[ '台球最新', "http://news.baidu.com/n?cmd=4&class=billiards&tn=rss", '体育', 8, '体育', 39 ],
	[ '娱乐最新', "http://news.baidu.com/n?cmd=4&class=enternews&tn=rss", '娱乐', 4, '深度报道', 25 ],
	[ '明星最新', "http://news.baidu.com/n?cmd=4&class=star&tn=rss", '明星', 15, '明星', 44 ],
	[ '爆料最新', "http://news.baidu.com/n?cmd=4&class=star_chuanwen&pn=1", '明星', 15, '明星', 44 ],
	[ '港台最新', "http://news.baidu.com/n?cmd=4&class=star_gangtai&pn=1", '娱乐', 4, '深度报道',25 ],
	[ '内地最新', "http://news.baidu.com/n?cmd=4&class=star_neidi&pn=1", '娱乐', 4, '深度报道',25 ],
	[ '欧美最新', "http://news.baidu.com/n?cmd=4&class=star_oumei&pn=1", '娱乐', 4, '深度报道',25 ],
	[ '日韩最新', "http://news.baidu.com/n?cmd=4&class=star_rihan&pn=1", '娱乐', 4, '深度报道',25 ],
	[ '电影最新', "http://news.baidu.com/n?cmd=4&class=film&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '电影花絮最新', "http://news.baidu.com/n?cmd=4&class=film_huaxu&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '电视最新', "http://news.baidu.com/n?cmd=4&class=tv&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '剧评最新', "http://news.baidu.com/n?cmd=4&class=tv_jupin&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '音乐最新', "http://news.baidu.com/n?cmd=4&class=music&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '综艺最新', "http://news.baidu.com/n?cmd=4&class=zongyi&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '演出最新', "http://news.baidu.com/n?cmd=4&class=yanchu&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '奖项最新', "http://news.baidu.com/n?cmd=4&class=jiangxiang&tn=rss", '娱乐', 4, '深度报道',25 ],
	[ '游戏最新', "http://news.baidu.com/n?cmd=4&class=gamenews&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '网络游戏最新', "http://news.baidu.com/n?cmd=4&class=netgames&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '电视游戏最新', "http://news.baidu.com/n?cmd=4&class=tvgames&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '电子竞技最新', "http://news.baidu.com/n?cmd=4&class=dianzijingji&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '热门游戏最新', "http://news.baidu.com/n?cmd=4&class=remenyouxi&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '魔兽世界最新', "http://news.baidu.com/n?cmd=4&class=WOW&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '教育最新', "http://news.baidu.com/n?cmd=4&class=edunews&tn=rss", '教育', 6, '教育', 41 ],
	[ '考试最新', "http://news.baidu.com/n?cmd=4&class=exams&tn=rss", '教育', 6, '教育', 41 ],
	[ '中考最新', "http://news.baidu.com/n?cmd=4&class=zhongkao&tn=rss", '教育', 6, '教育', 41 ],
	[ '高考最新', "http://news.baidu.com/n?cmd=4&class=gaokao&tn=rss", '教育', 6, '教育', 41 ],
	[ '考研最新', "http://news.baidu.com/n?cmd=4&class=kaoyan&tn=rss", '教育', 6, '教育', 41 ],
	[ '公务员考试最新', "http://news.baidu.com/n?cmd=4&class=gongwuyuan&tn=rss", '教育', 6, '教育', 41 ],
	[ '资格考试最新', "http://news.baidu.com/n?cmd=4&class=zigekaoshi&tn=rss", '教育', 6, '教育', 41 ],
	[ '留学最新', "http://news.baidu.com/n?cmd=4&class=abroad&tn=rss", '教育', 6, '教育', 41 ],
	[ '就业最新', "http://news.baidu.com/n?cmd=4&class=jiuye&tn=rss", '教育', 6, '教育', 41 ],
	[ '女人最新', "http://news.baidu.com/n?cmd=4&class=healthnews&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '潮流服饰最新', "http://news.baidu.com/n?cmd=4&class=chaoliufs&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '女性职场最新', "http://news.baidu.com/n?cmd=4&class=nvrentx&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '型男时尚最新', "http://news.baidu.com/n?cmd=4&class=xingnanss&tn=rss", '行业', 17, '行业热点', 23 ],
	[ '美容护肤最新', "http://news.baidu.com/n?cmd=4&class=meironghf&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '亲子母婴最新', "http://news.baidu.com/n?cmd=4&class=qinzimy&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '婚嫁新人最新', "http://news.baidu.com/n?cmd=4&class=hunjia&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '减肥健身最新', "http://news.baidu.com/n?cmd=4&class=jianfei&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '情感两性最新', "http://news.baidu.com/n?cmd=4&class=qinggan&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '星座最新', "http://news.baidu.com/n?cmd=4&class=xingzuo&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '健康养生最新', "http://news.baidu.com/n?cmd=4&class=jiankang&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '美食健康最新', "http://news.baidu.com/n?cmd=4&class=meishijk&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '保健养生最新', "http://news.baidu.com/n?cmd=4&class=baojian&tn=rss", '医疗保健', 5, '医疗保健', 42 ],
	[ '科技最新', "http://news.baidu.com/n?cmd=4&class=technnews&tn=rss", '科技', 7, '科技', 40 ],
	[ '手机最新', "http://news.baidu.com/n?cmd=4&class=cell&tn=rss", '科技', 7, '科技', 40 ],
	[ '手机新品最新', "http://news.baidu.com/n?cmd=4&class=cell_xinpin&tn=rss", '科技', 7, '科技', 40 ],
	[ '手机导购最新', "http://news.baidu.com/n?cmd=4&class=cell_daogou&tn=rss", '科技', 7, '科技', 40 ],
	[ '手机行情最新', "http://news.baidu.com/n?cmd=4&class=cell_hangqing&tn=rss", '科技', 7, '科技', 40 ],
	[ '数码最新', "http://news.baidu.com/n?cmd=4&class=digital&tn=rss", '科技', 7, '科技', 40 ],
	[ '数码新品最新', "http://news.baidu.com/n?cmd=4&class=digital_xinpin&tn=rss", '科技', 7, '科技', 40 ],
	[ '数码导购最新', "http://news.baidu.com/n?cmd=4&class=digital_daogou&tn=rss", '科技', 7, '科技', 40 ],
	[ '数码行情最新', "http://news.baidu.com/n?cmd=4&class=digital_hq&tn=rss", '科技', 7, '科技', 40 ],
	[ '电脑最新', "http://news.baidu.com/n?cmd=4&class=computer&tn=rss", '科技', 7, '科技', 40 ],
	[ '电脑新品最新', "http://news.baidu.com/n?cmd=4&class=comp_xinpin&tn=rss", '科技', 7, '科技', 40 ],
	[ '电脑导购最新', "http://news.baidu.com/n?cmd=4&class=comp_daogou&tn=rss", '科技', 7, '科技', 40 ],
	[ '电脑行情最新', "http://news.baidu.com/n?cmd=4&class=comp_hangqing&tn=rss", '科技', 7, '科技', 40 ],
	[ '科普最新', "http://news.baidu.com/n?cmd=4&class=discovery&tn=rss", '科技', 7, '科技', 40 ],
	[ '社会最新', "http://news.baidu.com/n?cmd=4&class=socianews&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '社会与法最新', "http://news.baidu.com/n?cmd=4&class=shyf&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '社会万象最新', "http://news.baidu.com/n?cmd=4&class=shwx&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '真情时刻最新', "http://news.baidu.com/n?cmd=4&class=zqsk&tn=rss", '社会', 10, '每日推荐', 33 ],
	[ '奇闻异事最新', "http://news.baidu.com/n?cmd=4&class=qwys&tn=rss", '社会', 10, '每日推荐', 33 ],
);

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'baidu_rss';
	$self->{ranks} = \@ranks;
	$self->{focus} = \@focus;
	$self->{latest} = \@latest;
	bless $self, $type;
}

sub get_item
{
    my ( $self, $html ) = @_;
    return unless $html;
	$html =~ m {
		<item>
		(?:.*?)  #回车换行: \cJ
		<title>
		(.*?)  #标题部分
		</title>
		(?:.*?)
		<link>
		(.*?)  #链接部分
		</link>
		(?:.*?)
		<pubDate>
		(.*?)  #生成日期
		</pubDate>		
		(?:.*?)
		<source>
		(.*?)  #资源
		</source>
		(?:.*?)
		<author>
		(.*?)  #作者
		</author>
		(?:.*?)
		<description>
		(.*?)  #正文
		</description>
		(?:.*?)
		</item>
    }sgix;
	my ($title, $link, $pubDate, $source, $author, $desc);

	$title = $self->remove_CDATA($1);
	$link = $self->remove_CDATA($2);
	$pubDate = $self->remove_CDATA($3);
	$source = $self->remove_CDATA($4);
	$author = $self->remove_CDATA($5);
	$desc = $self->remove_CDATA($6);

	return [ $title, $link, $pubDate, $source, $author, $desc ];
}

# Mon, 10 Sep 12 20:19:06 +0800, reserved for future improvement.
sub get_datetime { }

# Use of uninitialized value $str in substitution (s///) at lib//baidu.pm line 331
sub remove_CDATA
{
	my ($self, $str) = @_;
	if (! $str && $self->{'url'}) {
		$self->write_log( "Download NULL problem: " . $self->{'url'} );
		$str = '';
	}
	else {
		$str =~ s/<!\[CDATA\[//;
		$str =~ s/\]\]>//;
	}
	return $str;
}

sub insert_baidu
{
	my ($self, $h, $rank) = @_;

	#�� baidu��վ��ȡ�õ�������Ϣ.
	my $category = $self->{dbh}->quote($rank->[2]);
	my $item = $self->{dbh}->quote($rank->[0]);

	my $sql = qq{ insert into contexts
		(linkname,
		url,
		pubdate,
		author, 
		source,
		category,
		cate_id,
		item,
		iid,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubDate'},
		$h->{'author'},
		$h->{'source'},
		$category,
		$h->{'cate_id'},
		$item,
		$h->{'item_id'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)
	on duplicate key update
		content = $h->{'desc'},
		pubDate = $h->{'pubDate'}
	};
	$self->{dbh}->do($sql);
}

#t_baidu
sub insert_baidu_old
{
	my ($self, $h, $rank) = @_;
	# foreach my $key (keys %{$h}) { print $h->{$key}  . ", " if ($key ne 'desc'); }

	my $category = $self->{dbh}->quote($rank->[2]);
	my $item = $self->{dbh}->quote($rank->[0]);

	my $sql = qq{ insert into t_baidu
		(title,
		url,
		pubDate,
		source, 
		author, 
		category,
		cate_id,
		item,
		item_id,
		createdby,
		created,
		content
	) values(
		$h->{'title'}, 
		$h->{'url'},
		$h->{'pubDate'},
		$h->{'source'}, 
		$h->{'author'},
		$category,
		$h->{'cate_id'},
		$item,
		$h->{'item_id'},
		$h->{'createdby'},
		now(),
		$h->{'desc'}
	)
	on duplicate key update
		content = $h->{'desc'},
		pubDate = $h->{'pubDate'}
	};
	$self->{dbh}->do($sql);
}

sub select_category {
	my ( $self, $name ) = @_;
	my @row = ();
	$name = $self->{dbh}->quote($name);
	$sth = $self->{dbh}->prepare( qq{ select cid from categories where name=$name } );
	$sth->execute();
	@row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}
sub select_item {
	my ( $self, $rank, $cid, $createdby) = @_;
	my @row = ();
	my $item = $self->{dbh}->quote($rank->[0]);
	$sth = $self->{dbh}->prepare( qq{ select iid from items where name=$item } );
	$sth->execute();
	@row = $sth->fetchrow_array();
	$sth->finish();

	if(! $row[0]) {
		my $url = $self->{dbh}->quote($rank->[1]);
		my $category = $self->{dbh}->quote($rank->[2]);
		my $sql = qq{ insert into items(name, iurl, category, cid, description, createdby, created) values(
			$item, $url, $category, $cid, $item, $createdby, now())
		};

		$self->{dbh}->do($sql);
		return $self->{dbh}->last_insert_id(undef, undef, 'items', undef);
	}
	return $row[0];
}
sub select_items_by_cid {
	my ( $self, $cid ) = @_;
	my $aref = [];
	$sth = $self->{dbh}->prepare( q{ select iid, name, iurl from items where cid=$cid } );
	$sth->execute();
	$aref = $sth->fetchall_arrayref();
	$sth->finish();
	return $aref;
}

1;
