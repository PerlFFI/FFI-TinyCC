use strict;
use warnings;
use Test::More tests => 1;

pass 'okay';

diag ''; diag '';

eval q{
  use FFI::TinyCC;
  diag "lib=$_" for $FFI::TinyCC::ffi->lib;
};

diag "error: $@" if $@;

diag ''; 
