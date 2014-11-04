use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use if $^O eq 'MSWin32', 'Test::More', skip_all => 'unsupported on windows';
use Test::More tests => 1;
use FFI::TinyCC;
use FFI::Raw;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class qw( file dir );
use Config;

subtest 'dll' => sub {

  # TODO: on windows can we create a .a that points to
  # the dll and use that to indirectly add the dll?
  plan skip_all => 'unsupported on windows' if $^O eq 'MSWin32';
  plan tests => 2;
  
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $dll = file( $CWD, "bar." . FFI::TinyCC::_dlext() );

  subtest 'create' => sub {
    plan tests => 3;
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('dll') };
    is $@, '', 'tcc.set_output_type(dll)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "dll=$dll";
    eval { $tcc->output_file($dll) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    plan tests => 4;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($dll) };
    is $@, '', 'tcc.add_file';
    
    eval { $tcc->compile_string(q{
      extern const char *roger();
      const char *wrapper()
      {
        return roger();
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    my $ffi = eval { $tcc->get_ffi_raw('wrapper', FFI::Raw::str) };
    is $@, '', 'tcc.get_ffi_raw';
    
    is $ffi->call, "rabbit", 'ffi.call';

  };
  
};
