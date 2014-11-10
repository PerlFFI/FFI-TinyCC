use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 1;

pass 'okay';

diag ''; diag '';

eval q{
  use FFI::TinyCC;
  diag 'FFI::TinyCC::_lib=' . FFI::TinyCC::_lib();
};

diag "error: $@" if $@;

diag ''; 
