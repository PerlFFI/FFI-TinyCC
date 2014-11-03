use strict;
use warnings;
use 5.010;
use FFI::TinyCC;
use FFI::Raw;

my $tcc = FFI::TinyCC->new;

$tcc->compile_string(q{
  int
  calculate_square(int value)
  {
    return value*value;
  }
});

my $value = (shift @ARGV) // 4;

# $square isa FFI::Raw
my $square = $tcc->get_ffi_raw(
  'calculate_square',
  FFI::Raw::int,  # return type
  FFI::Raw::int,  # argument types
);

say $square->call($value);
