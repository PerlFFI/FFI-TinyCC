use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 4;
use FFI::TinyCC;
use FFI::Raw;

my $tcc = FFI::TinyCC->new;

my $callback = FFI::Raw::Callback->new(
  sub { $_[0] + $_[0] },
  FFI::Raw::int, FFI::Raw::int,
);

eval { $tcc->add_symbol('foo' => $callback) };
is $@, '', 'tcc.add_symbol';

eval { $tcc->compile_string(q{
extern int foo(int arg);
int
bar()
{
  return foo(3)*2;
}
})};
is $@, '', 'tcc.compile_string';

my $ffi = eval { FFI::Raw->new_from_ptr($tcc->get_symbol('bar'), FFI::Raw::int) };
is $@, '', 'FFI::Raw.new_from_ptr';

is $ffi->call, (3+3)*2, 'ffi.call';
