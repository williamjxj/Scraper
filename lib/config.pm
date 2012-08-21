package config;

require Exporter;
@ISA = qw( Exporter );
@EXPORT = qw(USER PASS HOST DSN LOGDIR VERSION CONTACTS URL URL1 KEYWORD KEYWORD_FILE OFILE EMAILS);

use constant URL => q{http://www.chinafnews.com};
use constant USER => 'dixitruth';
use constant PASS => 'dixi123456';
use constant HOST => 'localhost';
use constant DSN => 'DBI:mysql:dixi';
use constant LOGDIR => q{./logs/};
use constant VERSION => '1.0';
1;

