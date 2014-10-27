use strict;
use warnings;
use Test::More tests => 3;
use FFI::TinyCC;
use FindBin ();
use File::Spec;

my $inc = File::Spec->catdir($FindBin::Bin, 'c');

my $options = "-I$inc -L$inc -DFOO=22";

my $tcc = FFI::TinyCC->new;

eval { $tcc->set_options($options) };
is $@, '', 'tcc.set_options';

eval { $tcc->compile_string(q{

#include "foo.h"

int
main(int argc, char *argv[])
{
  return FOO;
}

})};

is $@, '', 'tcc.compile_string';

is $tcc->run, 22, 'tcc.run';
