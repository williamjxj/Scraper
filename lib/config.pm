package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS DSN BASE VERSION URL LOG HTML CATEGORY ITEM CONTEXTS CONTENTS CONTENTS_1 CONTENTS_NEW FOOD INTERVAL_DATE HOST RW_MODE);

use constant USER => q{dixitruth};
use constant PASS => q{dixi123456};
use constant DSN => q{DBI:mysql:dixi:hostname=localhost};
use constant VERSION => 1.0;
use constant BASE => q{/home/williamjxj/scraper/};
use constant LOG  => BASE.q{logs/};
use constant HTML => BASE.q{html/};
use constant CATEGORY => q{categories};
use constant ITEM => q{items};
use constant CONTENTS => q{contents};
use constant CONTENTS_1 => q{contents_1};
use constant CONTENTS_NEW => q{contents};
#use constant CONTENTS_NEW => q{contents_new};
use constant CONTEXTS => q{contexts};
use constant FOOD => q{食品};
use constant INTERVAL_DATE => 3;
use constant RW_MODE => "a+";

use constant HOST => q{localhost};
1;
