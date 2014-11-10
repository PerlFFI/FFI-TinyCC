use strict;
use warnings;
use Test::More tests => 1;

pass 'okay';

diag ''; diag '';

eval q{
  use FFI::TinyCC;
  diag 'FFI::TinyCC::_lib=' . FFI::TinyCC::_lib();
};

diag "error: $@" if $@;

diag ''; 
