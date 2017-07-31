use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;
use File::Temp qw( tempdir );
use File::chdir;
use Path::Class qw( file dir );
use Config;

subtest 'c source code' => sub {
  my $tcc = FFI::TinyCC->new;
  
  my $file = file($FindBin::Bin, 'c', 'return22.c');
  note "file = $file";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';

  is $tcc->run, 22, 'tcc.run';
};

done_testing;
