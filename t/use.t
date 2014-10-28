use strict;
use warnings;
use v5.10;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 2;

use_ok 'FFI::TinyCC';
use_ok 'FFI::TinyCC::Inline';
