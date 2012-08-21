package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN DSN_new LOG CHTML URL1 URL2 URL3 CATEGORY COUNTRY_STATE ITEM TOPIC DEFAULT_CITY DEFAULT_CATEGORY
VERSION INTERVAL_DATE);

use constant USER => 'dixitruth';
use constant PASS => 'dixi123456';
use constant HOST => 'localhost';
use constant DSN => 'DBI:mysql:dixi';
use constant LOG => q{../logs/};
use constant HTML => q{./html/};
use constant URL => q{http://www.chinafnews.com/};
use constant VERSION => '1.0';
use constant INTERVAL_DATE => '2';

1;

