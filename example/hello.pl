use strict;
use warnings;
use 5.010;
use FFI::TinyCC;
use FFI::Raw;

my $tcc = FFI::TinyCC->new;

$tcc->compile_string(<<EOF);
int
main(int argc, char *argv[])
{
  puts("hello world");
}
EOF

my $r = $tcc->run;

exit $r;
