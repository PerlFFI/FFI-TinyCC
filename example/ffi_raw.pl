use strict;
use warnings;
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

my $value = (shift @ARGV);
$value = 4 unless defined $value;

my $address = $tcc->get_symbol('calculate_square');

# $square isa FFI::Raw
my $square = FFI::Raw->new_from_ptr(
  $address,
  FFI::Raw::int,  # return type
  FFI::Raw::int,  # argument types
);

print $square->call($value), "\n";
