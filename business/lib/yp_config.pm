package yp_config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN DSN_new LOG CHTML URL1 URL2 URL3 URL4 CATEGORY CITY COUNTRY_STATE ITEM TOPIC DEFAULT_CITY DEFAULT_CATEGORY
VERSION INTERVAL_DATE);

use constant USER => 'yellowpage';
use constant PASS => 'william';
use constant HOST => 'localhost';
use constant DSN => 'DBI:mysql:yellowpage';
use constant LOG => q{../logs/};
use constant CHTML => q{./html/};
use constant URL1 => q{http://www.yellowpages.com/sitemap};
use constant URL2 => q{http://www.yellowpages.com/};
use constant URL3 => q{http://www.yellowpages.com/seattle-wa/categories/};
use constant URL4 => q{};
use constant DEFAULT_CITY => 'vancouver';
use constant DEFAULT_CATEGORY => 'services';
use constant VERSION => '2.0';
use constant INTERVAL_DATE => '2';

use constant CATEGORY => q{yp_category};
use constant CITY => q{yp_city};
use constant COUNTRY_STATE => q{yp_country_state};
use constant ITEM => q{yp_item};
use constant TOPIC => q{yp_topic};

1;

