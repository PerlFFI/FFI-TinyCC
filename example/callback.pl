use strict;
use warnings;
use 5.010;
use FFI::TinyCC;
use FFI::Raw;

my $say = FFI::Raw::Callback->new(
  sub { say $_[0] },
  FFI::Raw::void,
  FFI::Raw::str,
);

my $tcc = FFI::TinyCC->new;

$tcc->add_symbol(say => $say);

$tcc->compile_string(q{
extern void say(const char *);

int
main(int argc, char *argv[])
{
  int i;
  for(i=1; i<argc; i++)
  {
    say(argv[i]);
  }
}
});

# use '-' for the program name
my $r = $tcc->run('-', @ARGV);

exit $r;
