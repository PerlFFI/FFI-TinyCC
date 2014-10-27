use strict;
use warnings;
use FFI::TinyCC;
use Test::More tests => 1;

my $tcc = FFI::TinyCC->new;
isa_ok $tcc, 'FFI::TinyCC';

eval {
  use YAML ();
  note YAML::Dump($tcc);
};

