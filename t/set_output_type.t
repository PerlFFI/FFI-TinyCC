use strict;
use warnings;
use v5.10;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 4;
use FFI::TinyCC;

foreach my $type (qw( memory exe dll obj ))
{
  subtest $type => sub {
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type($type) };
    is $@, '', 'tcc.set_output_type';
  
  };
}
