use Test2::V0 -no_srand => 1;
use FindBin;
use FFI::TinyCC;
use Path::Tiny qw( path );

my $ok = subtest 'basic' => sub {
  my $tcc = FFI::TinyCC->new;
  isa_ok $tcc, 'FFI::TinyCC';
  
  my $file =  "$FindBin::Bin/c/return22.c";
  
  eval { $tcc->add_file($file) };
  is $@, '', 'tcc.compile_string';
  
  is $tcc->run, 22, 'tcc.run';
};

unless($ok)
{
  diag '';
  diag '';
  diag '';
  diag 'DID NOT WORK';
  diag '';
  diag '';
  diag '';

  my $share = path($FindBin::Bin)->parent->child('share');
  my $log = $share->child('build.log');
  
  diag "=== $log ===";
  if(-e $log)
  {
    diag $log->slurp;
  }
  else
  {
    diag "NO LOG";
  }

  my $dir = $^O eq 'MSWin32' ? 'cmd /c dir /s' : 'ls -lR' ;

  diag "=== $share ===";
  diag "+ $dir $share";
  diag `$dir $share`;
  
  eval { 
    my $dist_dir = dist_dir('FFI-TinyCC');
    diag "=== $dist_dir ===";
    diag "+ $dir $dist_dir";
    diag `$dir $dist_dir`;
  };
  if(my $error = $@)
  {
    diag "=== no dist_dir(FFI-TinyCC) ===";
    diag $error;
  }

  eval { 
    my $dist_dir = dist_dir('Alien-TinyCC');
    diag "=== $dist_dir ===";
    diag "+ $dir $dist_dir";
    diag `$dir $dist_dir`;
  };
  if(my $error = $@)
  {
    diag "=== no dist_dir(Alien-TinyCC) ===";
    diag $error;
  }
  
  eval {
    require Alien::TinyCC;
    my $inc = Alien::TinyCC->libtcc_include_path;
    my $lib = Alien::TinyCC->libtcc_library_path;
    diag "=== $inc ===";
    diag "+ $dir $inc";
    diag `$dir $inc`;
    diag "=== $lib ===";
    diag "+ $dir $lib";
    diag `$dir $lib`;
  };
  if(my $error = $@)
  {
    diag "=== no Alien::TinyCC ===";
    diag $error;
  }
  
}

done_testing;
