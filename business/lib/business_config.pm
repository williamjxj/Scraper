package business_config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN LOGDIR CHTML URL1 DEFAULT_CITY DEFAULT_CATEGORY
VERSION INTERVAL_DATE CUT_LENGTH BIZ CONTACT US_DATEFORMAT CA_DATEFORMAT);

use constant USER => 'biz_us';
use constant PASS => 'william';
use constant HOST => 'localhost';
use constant DSN => 'DBI:mysql:business_db';
use constant LOGDIR => q{./logs/};
use constant CHTML => q{./html/};
use constant URL1 => q{http://www.craigslist.org/about/sites};
use constant DEFAULT_CITY => 'vancouver';
use constant DEFAULT_CATEGORY => 'jobs';
use constant VERSION => '2.0';
use constant INTERVAL_DATE => '7';
use constant CUT_LENGTH => '198';

use constant BIZ => q{biz_us};
use constant CONTACT => q{biz_us_contact};

# Thu 25 Mar
use constant CA_DATEFORMAT => q{%a %d %b};
# Thu Jun 03
use constant US_DATEFORMAT => q{%a %b %d};

1;

