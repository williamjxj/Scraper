package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN LOGDIR VERSION URL HTML URL1 URL2 URL3 CATEGORY ITEM CHANNEL CONTEXT INTERVAL_DATE DBNAME);

use constant USER => q{dixitruth};
use constant PASS => q{dixi123456};
use constant HOST => q{localhost};
use constant DSN => q{DBI:mysql:dixi};
use constant LOGDIR => q{./logs/};
use constant VERSION => 1.0;
use constant HTML => q{./html/};
use constant URL => q{http://www.chinafnews.com};
use constant URL1 => q{http://www.chinafnews.com/};
use constant URL2 => q{http://www.chinafnews.com/news/};
use constant URL3 => q{http://www.chinafnews.com/news/hot/};
use constant CATEGORY => q{categories};
use constant ITEM => q{items};
use constant CHANNEL => q{channels};
use constant CONTEXT => q{contexts};
use constant INTERVAL_DATE => 6;
use constant DBNAME => q{contexts};

=comment
use constant NEWS = qq(
	hot, guonei, guoji, fangtan, jiankang, qiye, puguangtai, shendu, fagui, fiance, baogao
);
=end


1;

