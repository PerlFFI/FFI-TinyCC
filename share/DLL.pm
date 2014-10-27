package
  DLL;

use strict;
use warnings;
use autodie qw( :all );  # need IPC::System::Simple
use Alien::TinyCC;
use Archive::Ar 2.02;
use File::Spec;
use File::chdir;
use File::Temp qw( tempdir );
use File::Glob qw( bsd_glob );
use Config;
use File::Basename qw( dirname );
use base qw( Exporter );
use File::Copy qw( copy );

our @EXPORT = qw( tcc_clean tcc_build );

my $share = dirname $INC{'DLL.pm'};

sub tcc_clean
{
  local $CWD = $share;
  my @old = grep /libtcc\./, bsd_glob '*';
  unlink $_ for @old;
}

sub tcc_build
{
  if($^O eq 'MSWin32')
  {
    local $CWD = $share;
    copy(
      File::Spec->catfile(
        Alien::TinyCC->libtcc_library_path,
        'libtcc.dll',
      ),
      'libtcc.dll',
    ) || die "unable to copy $!";
  }
  else
  {
    local $CWD = $share;
    print "$CWD\n";
    my $lib = File::Spec->catfile(Alien::TinyCC->libtcc_library_path, 'libtcc.a');
    my $tcc = File::Spec->catfile(Alien::TinyCC->path_to_tcc, 'tcc');

    die "unable to find libtcc.a" unless -f $lib;
    die "unable to find tcc" unless -f $tcc;

    my $ar = Archive::Ar->new;
    $ar->read($lib);

    my $tmp = tempdir( CLEANUP => 1 );

    my @obj = map { File::Spec->catfile($tmp, $_) } do {
      local $CWD = $tmp;
      $ar->extract;
      bsd_glob '*.o';
    };

    my @cmd = ($Config{cc}, '-o' => File::Spec->catfile($CWD, "libtcc.$Config{dlext}"), '-shared', @obj);

    print "% @cmd\n";
    system @cmd;
  }
}

1;
