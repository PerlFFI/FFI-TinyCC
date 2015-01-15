use strict;
use warnings;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 3;
use FFI::TinyCC;
use FFI::Platypus::Declare qw( int );

my $tcc = FFI::TinyCC->new;

eval { $tcc->compile_string(q{int foo() { return 42; }}) };
is $@, '', 'tcc.compile_string';

my $ptr = eval { $tcc->get_symbol('foo') };
ok $ptr, "tcc.get_symbol('foo') == $ptr";

function [$ptr => 'foo'] => [] => int;
is foo(), 42, 'foo.call';
