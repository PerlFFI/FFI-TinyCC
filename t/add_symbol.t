use strict;
use warnings;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 2;
use FFI::TinyCC;

my $c_code = <<EOF;
extern int foo(int arg);
int
bar()
{
  return foo(3)*2;
}
EOF

subtest 'FFI::Raw' => sub {
  plan skip_all => 'test requires FFI::Raw' unless eval q{ use FFI::Raw 0.32 (); 1 };
  plan tests => 4;

  my $tcc = FFI::TinyCC->new;

  my $callback = FFI::Raw::Callback->new(
    sub { $_[0] + $_[0] },
    FFI::Raw::int(), FFI::Raw::int(),
  );

  eval { $tcc->add_symbol('foo' => $callback) };
  is $@, '', 'tcc.add_symbol';

  eval { $tcc->compile_string($c_code) };
  is $@, '', 'tcc.compile_string';

  my $ffi = eval { FFI::Raw->new_from_ptr($tcc->get_symbol('bar'), FFI::Raw::int()) };
  is $@, '', 'FFI::Raw.new_from_ptr';

  is $ffi->call, (3+3)*2, 'ffi.call';
};

subtest 'FFI::Platypus' => sub {
  plan tests => 4;

  use FFI::Platypus;

  my $tcc = FFI::TinyCC->new;
  my $ffi = FFI::Platypus->new;
  
  my $closure = $tcc->{foo} = $ffi->closure(sub { $_[0] + $_[0] });
  my $pointer = $ffi->cast('(int)->int' => 'opaque', $closure);
  note sprintf("address = 0x%x", $pointer);
  
  eval { $tcc->add_symbol('foo' => $pointer) };
  is $@, '', 'tcc.add_symbol';
  
  eval { $tcc->compile_string($c_code)};
  is $@, '', 'tcc.compile_string';
  
  my $f = eval { $ffi->function($tcc->get_symbol('bar') => [] => 'int') };
  is $@, '', 'ffi.function';
 
  is $f->call, (3+3)*2, 'f.call';
};

