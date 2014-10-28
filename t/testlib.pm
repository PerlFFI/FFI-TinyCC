package
  testlib;

use strict;
use warnings;
use v5.10;
use File::Spec;
use base qw( Exporter );

our @EXPORT = qw( _catfile _catdir );

sub _catfile
{
  my $path = File::Spec->catfile(@_);
  if($^O eq 'MSWin32')
  {
    $path = Win32::GetShortPathName($path);
  }
  $path;
}

sub _catdir
{
  my $path = File::Spec->catdir(@_);
  if($^O eq 'MSWin32')
  {
    $path = Win32::GetShortPathName($path);
  }
  $path;
}

1;
