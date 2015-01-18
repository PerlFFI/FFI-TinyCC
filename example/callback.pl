use strict;
use warnings;
use FFI::TinyCC;
use FFI::Platypus::Declare qw( opaque );

my $say = closure { print $_[0], "\n" };
my $ptr = cast '(string)->void' => opaque => $say;

my $tcc = FFI::TinyCC->new;
$tcc->add_symbol(say => $ptr);

$tcc->compile_string(<<EOF);
extern void say(const char *);

int
main(int argc, char *argv[])
{
  int i;
  for(i=0; i<argc; i++)
  {
    say(argv[i]);
  }
}
EOF

my $r = $tcc->run($0, @ARGV);

exit $r;
