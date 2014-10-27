use strict;
use warnings;
use v5.10;
use Test::More tests => 2;
use FFI::TinyCC;

my $tcc = FFI::TinyCC->new;

eval { $tcc->compile_string(q{ int main(int argc, char *argv[]) { return 22; } }) };
is $@, '', 'tcc.compile_string';

is $tcc->run, 22, 'tcc.run';
