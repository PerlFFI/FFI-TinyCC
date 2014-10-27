use strict;
use warnings;
use v5.10;
use Test::More tests => 3;
use FFI::TinyCC;
use FindBin ();
use File::Spec;

subtest 'c source code' => sub {
  plan tests => 2;

  my $tcc = FFI::TinyCC->new;
  
  my $file = File::Spec->catfile($FindBin::Bin, 'c', 'return22.c');
  note "file = $file";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

subtest 'obj' => sub {
  plan skip_all => 'TODO';
};

subtest 'dll' => sub {
  plan skip_all => 'TODO';
};
