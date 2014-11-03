use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 2;

use_ok 'FFI::TinyCC';
use_ok 'FFI::TinyCC::Inline';
