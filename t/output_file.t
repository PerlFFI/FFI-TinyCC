use strict;
use warnings;
use v5.10;
use FindBin ();
use lib $FindBin::Bin;
use testlib;
use Test::More tests => 3;
use FFI::TinyCC;
use Config;
use File::Temp qw( tempdir );
use File::chdir;
use FFI::Raw;
use Path::Class qw( file dir );

subtest exe => sub
{
  plan tests => 5;
  local $CWD = tempdir( CLEANUP => 1 );

  my $tcc = FFI::TinyCC->new;

  eval { $tcc->set_output_type('exe') };
  is $@, '', 'tcc.set_output_type(exe)';

  eval { $tcc->compile_string(q{
    int
    main(int argc, char *argv[])
    {
      return 42;
    }
  })};
  
  is $@, '', 'tcc.compile_string';
  
  my $exe = "foo$Config{exe_ext}";
  
  note "exe=" . file($CWD, $exe);
  
  eval { $tcc->output_file($exe) };
  is $@, '', 'tcc.output_file';
  
  ok -f $exe, "created output file";
  
  system file($CWD, $exe), 'list', 'form';
  is $? >> 8, 42, 'return value 42';

};

subtest obj => sub
{
  plan tests => 2;
  local $CWD = tempdir(CLEANUP => 1);
  
  my $obj = "foo$Config{obj_ext}";
  
  subtest 'create object' => sub {
    plan tests => 4;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->set_output_type('obj') };
    is $@, '', 'tcc.set_output_type(obj)';
    
    eval { $tcc->compile_string(q{
      int
      foo()
      {
        return 55;
      }
    })};
    is $@, '', 'tcc.compile_string';
  
    note "obj=" . file($CWD, $obj);
  
    eval { $tcc->output_file($obj) };
    is $@, '', 'tcc.output_file';
    
    ok -f $obj, "created output file";
  
  };
  
  subtest 'use object' => sub {
    plan tests => 3;
  
    my $tcc = FFI::TinyCC->new;
    
    eval { $tcc->add_file($obj) };
    is $@, '', 'tcc.add_file';
  
    eval { $tcc->compile_string(q{
      extern int foo();
      int
      main(int argc, char *argv[])
      {
        return foo();
      }
    })};
    is $@, '', 'tcc.compile_string';
    
    is eval { $tcc->run }, 55, 'tcc.run';
    note $@ if $@;
  };
  
};

subtest dll => sub {

  plan tests => 4;

  local $CWD = tempdir( CLEANUP => 1 );

  my $tcc = FFI::TinyCC->new;
  
  my $dll = file( $CWD, "bar." . FFI::TinyCC::_dlext() );
  
  eval { $tcc->set_output_type('dll') };
  is $@, '', 'tcc.set_output_type(dll)';
  
  $tcc->set_options('-D__WIN32__') if $^O eq 'MSWin32';
  
  eval { $tcc->compile_string(q{
    int
    bar()
#if __WIN32__
    __attribute__((dllexport))
#endif
    {
      return 47;
    }
  })};
  is $@, '', 'tcc.compile_string';

  note "dll=$dll";
  
  eval { $tcc->output_file($dll) };
  is $@, '', 'tcc.output_file';
  
  my $ffi = FFI::Raw->new(
    $dll, 'bar',
    FFI::Raw::int,
  );
  
  is $ffi->call(), 47, 'ffi.call';

};
