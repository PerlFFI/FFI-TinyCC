use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 1;
use FFI::TinyCC;

subtest 'basic' => sub {
  plan tests => 2;
  my $tcc = FFI::TinyCC->new;

  eval { $tcc->compile_string(q{ int main(int argc, char *argv[]) { return 22; } }) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

