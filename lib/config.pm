package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN VERSION URL HTML CATEGORY ITEM CHANNEL CONTEXTS INTERVAL_DATE DBNAME FOOD);

use constant USER => q{dixitruth};
use constant PASS => q{dixi123456};
use constant HOST => q{localhost};
use constant DSN => q{DBI:mysql:dixi};
use constant VERSION => 1.0;
use constant HTML => q{./html/};
use constant CATEGORY => q{categories};
use constant ITEM => q{items};
use constant CHANNEL => q{channels};
use constant CONTEXTS => q{contexts};
use constant INTERVAL_DATE => 7;
use constant DBNAME => q{contexts};
use constant FOOD => 3;

=comment
use constant NEWS = qq(
	hot, guonei, guoji, fangtan, jiankang, qiye, puguangtai, shendu, fagui, fiance, baogao
);
=end


1;

