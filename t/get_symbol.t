use strict;
use warnings;
use v5.10;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 3;
use FFI::TinyCC;
use FFI::Raw;

my $tcc = FFI::TinyCC->new;

eval { $tcc->compile_string(q{int foo() { return 42; }}) };
is $@, '', 'tcc.compile_string';

my $ptr = eval { $tcc->get_symbol('foo') };
ok $ptr, "tcc.get_symbol('foo') == $ptr";

my $foo = FFI::Raw->new_from_ptr($ptr, FFI::Raw::int);
is $foo->call, 42, 'foo.call';
