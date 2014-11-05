package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use lib 'share';
use My::DLL;

sub new
{
  my($class, %args) = @_;

  tcc_build();
  
  my $self = $class->SUPER::new(%args);

  $self->add_to_cleanup('share/libtcc.*');
  $self->add_to_cleanup('share/lib');
  $self->add_to_cleanup('share/build.log');
  
  $self;
}

1;
