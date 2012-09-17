package baidu;
# http://news.baidu.com/newscode.html

# 不然$category和$item 为乱码.
use utf8;
use encoding 'utf8';

use lib qw(./);
use config;
use common;
@ISA = qw(common);
use strict;
use Data::Dumper;
my ( $sth );


our @focus = (
	[ '国内焦点', "http://news.baidu.com/n?cmd=1&class=civilnews&tn=rss", '国内' ],
	[ '台湾焦点', "http://news.baidu.com/n?cmd=1&class=taiwan&tn=rss", '国内' ],
	[ '港澳焦点', "http://news.baidu.com/n?cmd=1&class=gangaotai&tn=rss", '国内' ],
	[ '国际焦点', "http://news.baidu.com/n?cmd=1&class=internews&tn=rss", '国际' ],
	[ '环球视野焦点', "http://news.baidu.com/n?cmd=1&class=hqsy&tn=rss", '国际' ],
	[ '国际人物焦点', "http://news.baidu.com/n?cmd=1&class=renwu&tn=rss", '国际' ],
	[ '军事焦点', "http://news.baidu.com/n?cmd=1&class=mil&tn=rss", '军事' ],
	[ '中国军情焦点', "http://news.baidu.com/n?cmd=1&class=zhongguojq&tn=rss", '军事' ],
	[ '台海聚焦焦点', "http://news.baidu.com/n?cmd=1&class=taihaijj&tn=rss", '军事' ],
	[ '国际军情焦点', "http://news.baidu.com/n?cmd=1&class=guojijq&tn=rss", '军事' ],
	[ '财经焦点', "http://news.baidu.com/n?cmd=1&class=finannews&tn=rss", '财经' ],
	[ '股票焦点', "http://news.baidu.com/n?cmd=1&class=stock&tn=rss", '财经' ],
	[ '理财焦点', "http://news.baidu.com/n?cmd=1&class=money&tn=rss", '财经' ],
	[ '宏观经济焦点', "http://news.baidu.com/n?cmd=1&class=hongguan&tn=rss", '财经' ],
	[ '产业经济焦点', "http://news.baidu.com/n?cmd=1&class=chanye&tn=rss", '财经' ],
	[ '互联网焦点', "http://news.baidu.com/n?cmd=1&class=internet&tn=rss", '科技' ],
	[ '人物动态焦点', "http://news.baidu.com/n?cmd=1&class=rwdt&tn=rss", '科技' ],
	[ '公司动态焦点', "http://news.baidu.com/n?cmd=1&class=gsdt&tn=rss", '科技' ],
	[ '搜索引擎焦点', "http://news.baidu.com/n?cmd=1&class=search_engine&tn=rss", '科技' ],
	[ '电子商务焦点', "http://news.baidu.com/n?cmd=1&class=e_commerce&tn=rss", '科技' ],
	[ '网络游戏焦点', "http://news.baidu.com/n?cmd=1&class=online_game&tn=rss", '科技' ],
	[ '房产焦点', "http://news.baidu.com/n?cmd=1&class=housenews&tn=rss", '房地产' ],
	[ '各地动态焦点', "http://news.baidu.com/n?cmd=1&class=gddt&tn=rss", '房地产' ],
	[ '政策风向焦点', "http://news.baidu.com/n?cmd=1&class=zcfx&tn=rss", '房地产' ],
	[ '市场走势焦点', "http://news.baidu.com/n?cmd=1&class=shichangzoushi&tn=rss", '房地产' ],
	[ '家居焦点', "http://news.baidu.com/n?cmd=1&class=fitment&tn=rss", '房地产' ],
	[ '汽车焦点', "http://news.baidu.com/n?cmd=1&class=autonews&tn=rss", '汽车' ],
	[ '新车焦点', "http://news.baidu.com/n?cmd=1&class=autobuy&tn=rss", '汽车' ],
	[ '导购焦点', "http://news.baidu.com/n?cmd=1&class=daogou&tn=rss", '汽车' ],
	[ '各地行情焦点', "http://news.baidu.com/n?cmd=1&class=hangqing&tn=rss", '汽车' ],
	[ '维修养护焦点', "http://news.baidu.com/n?cmd=1&class=weixiu&tn=rss", '体育' ],
	[ '体育焦点', "http://news.baidu.com/n?cmd=1&class=sportnews&tn=rss", '体育' ],
	[ 'NBA焦点', "http://news.baidu.com/n?cmd=1&class=nba&tn=rss", '体育' ],
	[ '国际足球焦点', "http://news.baidu.com/n?cmd=1&class=worldsoccer&tn=rss", '体育' ],
	[ '国内足球焦点', "http://news.baidu.com/n?cmd=1&class=chinasoccer&tn=rss", '体育' ],
	[ 'CBA焦点', "http://news.baidu.com/n?cmd=1&class=cba&tn=rss", '体育' ],
	[ '综合体育焦点', "http://news.baidu.com/n?cmd=1&class=othersports&tn=rss", '体育' ],
	[ '娱乐焦点', "http://news.baidu.com/n?cmd=1&class=enternews&tn=rss", '娱乐' ],
	[ '明星焦点', "http://news.baidu.com/n?cmd=1&class=star&tn=rss", '明星' ],
	[ '电影焦点', "http://news.baidu.com/n?cmd=1&class=film&tn=rss", '娱乐' ],
	[ '电视焦点', "http://news.baidu.com/n?cmd=1&class=tv&tn=rss", '娱乐' ],
	[ '音乐焦点', "http://news.baidu.com/n?cmd=1&class=music&tn=rss", '娱乐' ],
	[ '综艺焦点', "http://news.baidu.com/n?cmd=1&class=zongyi&tn=rss", '娱乐' ],
	[ '演出焦点', "http://news.baidu.com/n?cmd=1&class=yanchu&tn=rss", '明星' ],
	[ '奖项焦点', "http://news.baidu.com/n?cmd=1&class=jiangxiang&tn=rss", '娱乐' ],
	[ '游戏焦点', "http://news.baidu.com/n?cmd=1&class=gamenews&tn=rss", '研究' ],
	[ '网络游戏焦点', "http://news.baidu.com/n?cmd=1&class=netgames&tn=rss", '研究' ],
	[ '电视游戏焦点', "http://news.baidu.com/n?cmd=1&class=tvgames&tn=rss", '研究' ],
	[ '电子竞技焦点', "http://news.baidu.com/n?cmd=1&class=dianzijingji&tn=rss", '研究' ],
	[ '热门游戏焦点', "http://news.baidu.com/n?cmd=1&class=remenyouxi&tn=rss", '研究' ],
	[ '魔兽世界焦点', "http://news.baidu.com/n?cmd=1&class=WOW&tn=rss", '研究' ],
	[ '教育焦点', "http://news.baidu.com/n?cmd=1&class=edunews&tn=rss", '教育' ],
	[ '考试焦点', "http://news.baidu.com/n?cmd=1&class=exams&tn=rss", '教育' ],
	[ '留学焦点', "http://news.baidu.com/n?cmd=1&class=abroad&tn=rss", '教育' ],
	[ '就业焦点', "http://news.baidu.com/n?cmd=1&class=jiuye&tn=rss", '教育' ],
	[ '女人焦点', "http://news.baidu.com/n?cmd=1&class=healthnews&tn=rss", '行业' ],
	[ '潮流服饰焦点', "http://news.baidu.com/n?cmd=1&class=chaoliufs&tn=rss", '行业' ],
	[ '美容护肤焦点', "http://news.baidu.com/n?cmd=1&class=meironghf&tn=rss", '行业' ],
	[ '减肥健身焦点', "http://news.baidu.com/n?cmd=1&class=jianfei&tn=rss", '行业' ],
	[ '情感两性焦点', "http://news.baidu.com/n?cmd=1&class=qinggan&tn=rss", '行业' ],
	[ '健康养生焦点', "http://news.baidu.com/n?cmd=1&class=jiankang&tn=rss", '行业' ],
	[ '科技焦点', "http://news.baidu.com/n?cmd=1&class=technnews&tn=rss", '行业' ],
	[ '手机焦点', "http://news.baidu.com/n?cmd=1&class=cell&tn=rss", '行业' ],
	[ '数码焦点', "http://news.baidu.com/n?cmd=1&class=digital&tn=rss", '行业' ],
	[ '电脑焦点', "http://news.baidu.com/n?cmd=1&class=computer&tn=rss", '行业' ],
	[ '科普焦点', "http://news.baidu.com/n?cmd=1&class=discovery&tn=rss", '行业' ],
	[ '社会焦点', "http://news.baidu.com/n?cmd=1&class=socianews&tn=rss", '社会' ],
	[ '社会与法焦点', "http://news.baidu.com/n?cmd=1&class=shyf&tn=rss", '社会' ],
	[ '社会万象焦点', "http://news.baidu.com/n?cmd=1&class=shwx&tn=rss", '社会' ],
	[ '真情时刻焦点', "http://news.baidu.com/n?cmd=1&class=zqsk&tn=rss", '社会' ],
	[ '奇闻异事焦点', "http://news.baidu.com/n?cmd=1&class=qwys&tn=rss", '社会' ],
);

our @latest = (	
	[ '国内最新', "http://news.baidu.com/n?cmd=4&class=civilnews&tn=rss", '国内' ],
	[ '时政要闻最新', "http://news.baidu.com/n?cmd=4&class=shizheng&tn=rss", '国内' ],
	[ '高层动态最新', "http://news.baidu.com/n?cmd=4&class=gaoceng&tn=rss", '国内' ],
	[ '人事任免最新', "http://news.baidu.com/n?cmd=4&class=gaoceng&tn=rss", '国内' ],
	[ '台湾最新', "http://news.baidu.com/n?cmd=4&class=taiwan&tn=rss", '国内' ],
	[ '历史档案最新', "http://news.baidu.com/n?cmd=4&class=lishi&tn=rss", '国内' ],
	[ '台湾民生最新', "http://news.baidu.com/n?cmd=4&class=twms&tn=rss", '国内' ],
	[ '港澳最新', "http://news.baidu.com/n?cmd=4&class=twms&tn=rss", '国内' ],
	[ '国际最新', "http://news.baidu.com/n?cmd=4&class=internews&tn=rss", '国际' ],
	[ '环球视野最新', "http://news.baidu.com/n?cmd=4&class=hqsy&tn=rss", '国际' ],
	[ '国际人物最新', "http://news.baidu.com/n?cmd=4&class=renwu&tn=rss", '国际' ],
	[ '军事最新', "http://news.baidu.com/n?cmd=4&class=mil&tn=rss", '军事' ],
	[ '中国军情最新', "http://news.baidu.com/n?cmd=4&class=zhongguojq&tn=rss", '军事' ],
	[ '台海聚焦最新', "http://news.baidu.com/n?cmd=4&class=taihaijj&tn=rss", '军事' ],
	[ '国际军情最新', "http://news.baidu.com/n?cmd=4&class=guojijq&tn=rss", '军事' ],
	[ '财经最新', "http://news.baidu.com/n?cmd=4&class=finannews&tn=rss", '财经' ],
	[ '股票最新', "http://news.baidu.com/n?cmd=4&class=stock&tn=rss", '财经' ],
	[ '大盘最新', "http://news.baidu.com/n?cmd=4&class=dapan&tn=rss", '财经' ],
	[ '个股最新', "http://news.baidu.com/n?cmd=4&class=gegu&tn=rss", '财经' ],
	[ '新股最新', "http://news.baidu.com/n?cmd=4&class=xingu&tn=rss", '财经' ],
	[ '权证最新', "http://news.baidu.com/n?cmd=4&class=warrant&tn=rss", '财经' ],
	[ '理财最新', "http://news.baidu.com/n?cmd=4&class=money&tn=rss", '财经' ],
	[ '基金最新', "http://news.baidu.com/n?cmd=4&class=fund&tn=rss", '财经' ],
	[ '银行最新', "http://news.baidu.com/n?cmd=4&class=bank&tn=rss", '财经' ],
	[ '贵金属最新', "http://news.baidu.com/n?cmd=4&class=nmetal&tn=rss", '财经' ],
	[ '保险最新', "http://news.baidu.com/n?cmd=4&class=insurance&tn=rss", '财经' ],
	[ '外汇最新', "http://news.baidu.com/n?cmd=4&class=forex&tn=rss", '财经' ],
	[ '期货最新', "http://news.baidu.com/n?cmd=4&class=futures&tn=rss", '财经' ],
	[ '宏观经济最新', "http://news.baidu.com/n?cmd=4&class=hongguan&tn=rss", '财经' ],
	[ '国内最新', "http://news.baidu.com/n?cmd=4&class=hg_guonei&tn=rss", '财经' ],
	[ '国际最新', "http://news.baidu.com/n?cmd=4&class=hg_guoji&tn=rss", '财经' ],
	[ '产业经济最新', "http://news.baidu.com/n?cmd=4&class=chanye&tn=rss", '财经' ],
	[ '互联网最新', "http://news.baidu.com/n?cmd=4&class=internet&tn=rss", '科技' ],
	[ '人物动态最新', "http://news.baidu.com/n?cmd=4&class=rwdt&tn=rss", '科技' ],
	[ '公司动态最新', "http://news.baidu.com/n?cmd=4&class=gsdt&tn=rss", '科技' ],
	[ '搜索引擎最新', "http://news.baidu.com/n?cmd=4&class=search_engine&tn=rss", '科技' ],
	[ '电子商务最新', "http://news.baidu.com/n?cmd=4&class=e_commerce&tn=rss", '科技' ],
	[ '网络游戏最新', "http://news.baidu.com/n?cmd=4&class=online_game&tn=rss", '科技' ],
	[ '房产最新', "http://news.baidu.com/n?cmd=4&class=housenews&tn=rss", '房地产' ],
	[ '各地动态最新', "http://news.baidu.com/n?cmd=4&class=gddt&tn=rss", '房地产' ],
	[ '政策风向最新', "http://news.baidu.com/n?cmd=4&class=zcfx&tn=rss", '房地产' ],
	[ '市场走势最新', "http://news.baidu.com/n?cmd=4&class=shichangzoushi&tn=rss", '房地产' ],
	[ '家居最新', "http://news.baidu.com/n?cmd=4&class=fitment&tn=rss", '房地产' ],
	[ '汽车最新', "http://news.baidu.com/n?cmd=4&class=autonews&tn=rss", '汽车' ],
	[ '新车最新', "http://news.baidu.com/n?cmd=4&class=autobuy&tn=rss", '汽车' ],
	[ '导购最新', "http://news.baidu.com/n?cmd=4&class=daogou&tn=rss", '汽车' ],
	[ '各地行情最新', "http://news.baidu.com/n?cmd=4&class=hangqing&tn=rss", '汽车' ],
	[ '维修养护最新', "http://news.baidu.com/n?cmd=4&class=weixiu&tn=rss", '汽车' ],
	[ '体育最新', "http://news.baidu.com/n?cmd=4&class=sportnews&tn=rss", '体育' ],
	[ 'NBA最新', "http://news.baidu.com/n?cmd=4&class=nba&tn=rss", '体育' ],
	[ '国际足球最新', "http://news.baidu.com/n?cmd=4&class=worldsoccer&tn=rss", '体育' ],
	[ '英超最新', "http://news.baidu.com/n?cmd=4&class=Yingchao&tn=rss", '体育' ],
	[ '意甲最新', "http://news.baidu.com/n?cmd=4&class=Yijia&tn=rss", '体育' ],
	[ '西甲最新', "http://news.baidu.com/n?cmd=4&class=Xijia&tn=rss", '体育' ],
	[ '足球明星最新', "http://news.baidu.com/n?cmd=4&class=Zq_star&tn=rss", '体育' ],
	[ '曼联最新', "http://news.baidu.com/n?cmd=4&class=Manutd&tn=rss", '体育' ],
	[ '阿森纳最新', "http://news.baidu.com/n?cmd=4&class=Arsenal&tn=rss", '体育' ],
	[ '切尔西最新', "http://news.baidu.com/n?cmd=4&class=Chelsea&tn=rss", '体育' ],
	[ '利物浦最新', "http://news.baidu.com/n?cmd=4&class=Liverpool&tn=rss", '体育' ],
	[ 'AC米兰最新', "http://news.baidu.com/n?cmd=4&class=ACMilan&tn=rss", '体育' ],
	[ '国际米兰最新', "http://news.baidu.com/n?cmd=4&class=InterMilan&tn=rss", '体育' ],
	[ '尤文图斯最新', "http://news.baidu.com/n?cmd=4&class=Juventus&tn=rss", '体育' ],
	[ '皇马最新', "http://news.baidu.com/n?cmd=4&class=RealMadrid&tn=rss", '体育' ],
	[ '巴塞罗那最新', "http://news.baidu.com/n?cmd=4&class=Barcelona&tn=rss", '体育' ],
	[ '拜仁最新', "http://news.baidu.com/n?cmd=4&class=Bayen&tn=rss", '体育' ],
	[ '国内足球最新', "http://news.baidu.com/n?cmd=4&class=chinasoccer&tn=rss", '体育' ],
	[ '男足最新', "http://news.baidu.com/n?cmd=4&class=nanzu&tn=rss", '体育' ],
	[ '女足最新', "http://news.baidu.com/n?cmd=4&class=nvzu&tn=rss", '体育' ],
	[ '中超最新', "http://news.baidu.com/n?cmd=4&class=zhongchao&tn=rss", '体育' ],
	[ '球迷最新', "http://news.baidu.com/n?cmd=4&class=cn_qiumi&tn=rss", '体育' ],
	[ 'CBA最新', "http://news.baidu.com/n?cmd=4&class=cba&tn=rss", '体育' ],
	[ '赛事最新', "http://news.baidu.com/n?cmd=4&class=cba_match&tn=rss", '体育' ],
	[ '综合体育最新', "http://news.baidu.com/n?cmd=4&class=othersports&tn=rss", '体育' ],
	[ '排球最新', "http://news.baidu.com/n?cmd=4&class=volleyball&tn=rss", '体育' ],
	[ '乒乓球最新', "http://news.baidu.com/n?cmd=4&class=table-tennis&tn=rss", '体育' ],
	[ '羽毛球最新', "http://news.baidu.com/n?cmd=4&class=badminton&tn=rss", '体育' ],
	[ '田径最新', "http://news.baidu.com/n?cmd=4&class=Athletics&tn=rss", '体育' ],
	[ '游泳最新', "http://news.baidu.com/n?cmd=4&class=swimming&tn=rss", '体育' ],
	[ '体操最新' =>"http://news.baidu.com/n?cmd=4&class=Gymnastics&tn=rss", '体育' ],
	[ '网球最新', "http://news.baidu.com/n?cmd=4&class=volleyball&tn=rss", '体育' ],
	[ '赛车最新', "http://news.baidu.com/n?cmd=4&class=F1&tn=rss", '体育' ],
	[ '拳击最新', "http://news.baidu.com/n?cmd=4&class=boxing&tn=rss", '体育' ],
	[ '台球最新', "http://news.baidu.com/n?cmd=4&class=billiards&tn=rss", '体育' ],
	[ '娱乐最新', "http://news.baidu.com/n?cmd=4&class=enternews&tn=rss", '娱乐' ],
	[ '明星最新', "http://news.baidu.com/n?cmd=4&class=star&tn=rss", '明星' ],
	[ '爆料最新', "http://news.baidu.com/n?cmd=4&class=star_chuanwen&pn=1", '明星' ],
	[ '港台最新', "http://news.baidu.com/n?cmd=4&class=star_gangtai&pn=1", '娱乐' ],
	[ '内地最新', "http://news.baidu.com/n?cmd=4&class=star_neidi&pn=1", '娱乐' ],
	[ '欧美最新', "http://news.baidu.com/n?cmd=4&class=star_oumei&pn=1", '娱乐' ],
	[ '日韩最新', "http://news.baidu.com/n?cmd=4&class=star_rihan&pn=1", '娱乐' ],
	[ '电影最新', "http://news.baidu.com/n?cmd=4&class=film&tn=rss", '娱乐' ],
	[ '电影花絮最新', "http://news.baidu.com/n?cmd=4&class=film_huaxu&tn=rss", '娱乐' ],
	[ '电视最新', "http://news.baidu.com/n?cmd=4&class=tv&tn=rss", '娱乐' ],
	[ '剧评最新', "http://news.baidu.com/n?cmd=4&class=tv_jupin&tn=rss", '娱乐' ],
	[ '音乐最新', "http://news.baidu.com/n?cmd=4&class=music&tn=rss", '娱乐' ],
	[ '综艺最新', "http://news.baidu.com/n?cmd=4&class=zongyi&tn=rss", '娱乐' ],
	[ '演出最新', "http://news.baidu.com/n?cmd=4&class=yanchu&tn=rss", '娱乐' ],
	[ '奖项最新', "http://news.baidu.com/n?cmd=4&class=jiangxiang&tn=rss", '娱乐' ],
	[ '游戏最新', "http://news.baidu.com/n?cmd=4&class=gamenews&tn=rss", '行业' ],
	[ '网络游戏最新', "http://news.baidu.com/n?cmd=4&class=netgames&tn=rss", '行业' ],
	[ '电视游戏最新', "http://news.baidu.com/n?cmd=4&class=tvgames&tn=rss", '行业' ],
	[ '电子竞技最新', "http://news.baidu.com/n?cmd=4&class=dianzijingji&tn=rss", '行业' ],
	[ '热门游戏最新', "http://news.baidu.com/n?cmd=4&class=remenyouxi&tn=rss", '行业' ],
	[ '魔兽世界最新', "http://news.baidu.com/n?cmd=4&class=WOW&tn=rss", '行业' ],
	[ '教育最新', "http://news.baidu.com/n?cmd=4&class=edunews&tn=rss", '教育' ],
	[ '考试最新', "http://news.baidu.com/n?cmd=4&class=exams&tn=rss", '教育' ],
	[ '中考最新', "http://news.baidu.com/n?cmd=4&class=zhongkao&tn=rss", '教育' ],
	[ '高考最新', "http://news.baidu.com/n?cmd=4&class=gaokao&tn=rss", '教育' ],
	[ '考研最新', "http://news.baidu.com/n?cmd=4&class=kaoyan&tn=rss", '教育' ],
	[ '公务员考试最新', "http://news.baidu.com/n?cmd=4&class=gongwuyuan&tn=rss", '教育' ],
	[ '资格考试最新', "http://news.baidu.com/n?cmd=4&class=zigekaoshi&tn=rss", '教育' ],
	[ '留学最新', "http://news.baidu.com/n?cmd=4&class=abroad&tn=rss", '教育' ],
	[ '就业最新', "http://news.baidu.com/n?cmd=4&class=jiuye&tn=rss", '教育' ],
	[ '女人最新', "http://news.baidu.com/n?cmd=4&class=healthnews&tn=rss", '行业' ],
	[ '潮流服饰最新', "http://news.baidu.com/n?cmd=4&class=chaoliufs&tn=rss", '行业' ],
	[ '女性职场最新', "http://news.baidu.com/n?cmd=4&class=nvrentx&tn=rss", '行业' ],
	[ '型男时尚最新', "http://news.baidu.com/n?cmd=4&class=xingnanss&tn=rss", '行业' ],
	[ '美容护肤最新', "http://news.baidu.com/n?cmd=4&class=meironghf&tn=rss", '医疗保健' ],
	[ '亲子母婴最新', "http://news.baidu.com/n?cmd=4&class=qinzimy&tn=rss", '医疗保健' ],
	[ '婚嫁新人最新', "http://news.baidu.com/n?cmd=4&class=hunjia&tn=rss", '医疗保健' ],
	[ '减肥健身最新', "http://news.baidu.com/n?cmd=4&class=jianfei&tn=rss", '医疗保健' ],
	[ '情感两性最新', "http://news.baidu.com/n?cmd=4&class=qinggan&tn=rss", '医疗保健' ],
	[ '星座最新', "http://news.baidu.com/n?cmd=4&class=xingzuo&tn=rss", '医疗保健' ],
	[ '健康养生最新', "http://news.baidu.com/n?cmd=4&class=jiankang&tn=rss", '医疗保健' ],
	[ '美食健康最新', "http://news.baidu.com/n?cmd=4&class=meishijk&tn=rss", '医疗保健' ],
	[ '保健养生最新', "http://news.baidu.com/n?cmd=4&class=baojian&tn=rss", '医疗保健' ],
	[ '科技最新', "http://news.baidu.com/n?cmd=4&class=technnews&tn=rss", '科技' ],
	[ '手机最新', "http://news.baidu.com/n?cmd=4&class=cell&tn=rss", '科技' ],
	[ '手机新品最新', "http://news.baidu.com/n?cmd=4&class=cell_xinpin&tn=rss", '科技' ],
	[ '手机导购最新', "http://news.baidu.com/n?cmd=4&class=cell_daogou&tn=rss", '科技' ],
	[ '手机行情最新', "http://news.baidu.com/n?cmd=4&class=cell_hangqing&tn=rss", '科技' ],
	[ '数码最新', "http://news.baidu.com/n?cmd=4&class=digital&tn=rss", '科技' ],
	[ '数码新品最新', "http://news.baidu.com/n?cmd=4&class=digital_xinpin&tn=rss", '科技' ],
	[ '数码导购最新', "http://news.baidu.com/n?cmd=4&class=digital_daogou&tn=rss", '科技' ],
	[ '数码行情最新', "http://news.baidu.com/n?cmd=4&class=digital_hq&tn=rss", '科技' ],
	[ '电脑最新', "http://news.baidu.com/n?cmd=4&class=computer&tn=rss", '科技' ],
	[ '电脑新品最新', "http://news.baidu.com/n?cmd=4&class=comp_xinpin&tn=rss", '科技' ],
	[ '电脑导购最新', "http://news.baidu.com/n?cmd=4&class=comp_daogou&tn=rss", '科技' ],
	[ '电脑行情最新', "http://news.baidu.com/n?cmd=4&class=comp_hangqing&tn=rss", '科技' ],
	[ '科普最新', "http://news.baidu.com/n?cmd=4&class=discovery&tn=rss", '科技' ],
	[ '社会最新', "http://news.baidu.com/n?cmd=4&class=socianews&tn=rss", '社会' ],
	[ '社会与法最新', "http://news.baidu.com/n?cmd=4&class=shyf&tn=rss", '社会' ],
	[ '社会万象最新', "http://news.baidu.com/n?cmd=4&class=shwx&tn=rss", '社会' ],
	[ '真情时刻最新', "http://news.baidu.com/n?cmd=4&class=zqsk&tn=rss", '社会' ],
	[ '奇闻异事最新', "http://news.baidu.com/n?cmd=4&class=qwys&tn=rss", '社会' ],
);

sub new {
	my ( $type, $dbh_handle ) = @_;
	my $self = {};
	$self->{dbh} = $dbh_handle;
	$self->{app} = 'baidu_rss';
	$self->{focus} = \@focus;
	$self->{latest} = \@latest;
	bless $self, $type;
}

sub get_non_rss
{
    my ( $self, $html ) = @_;
    return unless $html;
    my $aref;
	while ($html =~ m {
		<div>
		(?:.*?)
		<a
		(?:.*?)
		href="
		(.*?)  #链接地址
		"
		(?:.*?)
		>
		(.*?)  # 标题
		<span\sclass="c">
		(.*?)  # 来源
		</span>
		(.*?)  # 正文
		</div>
    }sgix) {
		my ($title, $link, $pubDate, $source, $author, $desc);
	
		$link = $1;
		$title = $2;
		($source, $pubDate) = split('/\s+/', $3);
		$desc = $6;
		$author = $1;
		
		push (@{$aref}, [ $title, $link, $pubDate, $source, $author, $desc ]);
    }
    return $aref;
}

sub get_item
{
    my ( $self, $html ) = @_;
    return unless $html;
    my $aref;
	while ($html =~ m {
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
    }sgix) {
		my ($title, $link, $pubDate, $source, $author, $desc);
	
		$title = $self->remove_CDATA($1);
		$link = $self->remove_CDATA($2);
		$pubDate = $self->remove_CDATA($3);
		$source = $self->remove_CDATA($4);
		$author = $self->remove_CDATA($5);
		$desc = $self->remove_CDATA($6);
	
		push (@{$aref}, [ $title, $link, $pubDate, $source, $author, $desc ]);
    }
    return $aref;
}

# Mon, 10 Sep 12 20:19:06 +0800, reserved for future improvement.
sub get_datetime { }

# Use of uninitialized value $str in substitution (s///) at lib//baidu.pm line 331
sub remove_CDATA
{
	my ($self, $str) = @_;
	if (! $str && $self->{'url'}) {
		$self->write_log( "Download NULL problem[".__FILE__.",".__LINE__."]: ".$self->{'url'} );
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

	# foreach my $key (keys %{$h}) { print $h->{$key}  . ", " if ($key ne 'desc'); }
	my $category = $self->{dbh}->quote($rank->[2]);
	my $item = $self->{dbh}->quote($rank->[0]);

	my $sql = qq{ insert into contents
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

sub select_category {
	my ( $self, $name ) = @_;
	my @row = ();
	$sth = $self->{dbh}->prepare( "select cid from categories where name = ?" );
	$sth->bind_param(1, $name); # $sth->execute($name);
	$sth->execute();
	@row = $sth->fetchrow_array();
	$sth->finish();
	return $row[0];
}
sub select_item {
	my ( $self, $rank, $h) = @_;
	my @row = ();
	my $item = $rank->[0];
	$sth = $self->{dbh}->prepare( qq{ select iid from items where name=? and cid=? } );
	$sth->execute($item, $h->{'cate_id'});
	@row = $sth->fetchrow_array();
	$sth->finish();

	if(! $row[0]) {
		my $url = $self->{dbh}->quote($rank->[1]);
		my $sql = qq{ insert into items(name, iurl, category, cid, description, createdby, created) values(
			$h->{'item'}, $url, $h->{'category'}, $h->{'cate_id'}, $h->{'item'}, $h->{'createdby'}, now())
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
