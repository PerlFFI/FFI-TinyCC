use strict;
use warnings;
use Test::More tests => 3;
use FFI::TinyCC;
use FindBin;
use File::Spec;

my $tcc = FFI::TinyCC->new;

my $inc = File::Spec->catfile($FindBin::Bin, 'c');

note "inc=$inc";

eval { $tcc->add_sysinclude_path($inc) };
is $@, '', 'tcc.add_sysinclude_path';

eval { $tcc->compile_string(q{
#include <foo.h>
int 
main(int argc, char *argv[])
{
  return VALUE_22;
}
})};
is $@, '', 'tcc.compile_string';

is eval { $tcc->run }, 22, 'tcc.run';

