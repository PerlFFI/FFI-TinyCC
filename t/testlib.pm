package
  testlib;

use strict;
use warnings;
use 5.010;
use Config;
use Path::Class qw( file dir );

my $dlext = $^O eq 'MSWin32' ? 'dll' : $Config{dlext};

$ENV{FFI_TINYCC_LIBTCC_SO} = file($INC{'testlib.pm'})
  ->absolute
  ->dir
  ->parent
  ->file('share', "libtcc.$dlext")
  ->stringify;

1;
