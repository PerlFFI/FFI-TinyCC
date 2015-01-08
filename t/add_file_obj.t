use strict;
use warnings;
use 5.010;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 1;
use FFI::TinyCC;
use FFI::Raw;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class qw( file dir );
use Config;

subtest 'obj' => sub {

  plan tests => 2;
  
  local $CWD = tempdir( CLEANUP => 1 );
  
  my $obj = file($CWD, "foo$Config{obj_ext}");
  
  subtest 'create' => sub {
    plan tests => 3;
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('obj') };
    is $@, '', 'tcc.set_output_type(obj)';
    
    eval { $tcc->compile_string(q{
      const char *
      roger()
      {
        return "rabbit";
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "obj=$obj";
    eval { $tcc->output_file($obj) };
    is $@, '', 'tcc.output_file';
  };
  
  subtest 'use' => sub {
  
    plan tests => 4;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($obj) };
    is $@, '', 'tcc.add_file';
    
    eval { $tcc->compile_string(q{
      extern const char *roger();
      const char *wrapper()
      {
        return roger();
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    my $ffi = eval { FFI::Raw->new_from_ptr($tcc->get_symbol('wrapper'), FFI::Raw::str) };
    is $@, '', 'FFI::Raw.new_from_ptr';
    
    is $ffi->call, "rabbit", 'ffi.call';
  
  };

};

