package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS DSN BASE VERSION URL LOG HTML CATEGORY ITEM CONTEXTS CONTENTS CONTENTS_1 FOOD INTERVAL_DATE);

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
use constant CONTEXTS => q{contexts};
use constant FOOD => q{食品};
use constant INTERVAL_DATE => 7;
use constant RW_MODE => "a";

1;