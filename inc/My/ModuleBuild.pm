package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use lib 'share';
use DLL;  # share/DLL.pm

sub new
{
  my($class, %args) = @_;
  
  eval { tcc_build() };
  if($@) 
  {
    warn $@;
    exit;
  }
  
  my $self = $class->SUPER::new(%args);

  $self->add_to_cleanup('share/libtcc.*');
  
  $self;
}

1;
