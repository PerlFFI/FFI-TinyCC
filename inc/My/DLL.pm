package My::DLL;

use strict;
use warnings;
use v5.10;
use autodie qw( :all );  # need IPC::System::Simple
use Alien::TinyCC;
use Archive::Ar 2.02;
use File::Temp qw( tempdir );
use File::Glob qw( bsd_glob );
use Config;
use File::Basename qw( dirname basename );
use base qw( Exporter );
use File::Copy qw( copy );
use Path::Class::File ();
use File::chdir;

our @EXPORT = qw( tcc_clean tcc_build );

my $share = Path::Class::File
  ->new(dirname $INC{'My/DLL.pm'})
  ->absolute
  ->dir
  ->parent
  ->subdir('share');

sub tcc_clean
{
  unlink $_ for grep { $_->basename =~ /^libtcc\./ } $share->children;
  if(-d $share->subdir('lib'))
  {
    unlink $_ for $share->subdir('lib')->children;
    rmdir $share->subdir('lib');
  }
}

sub tcc_build
{
  tcc_clean();

  my $libdir = Path::Class::Dir->new(
    Alien::TinyCC->libtcc_library_path,
  )->absolute;

  if($^O eq 'MSWin32')
  {
    do {
      my $from = $libdir->file('libtcc.dll');
      my $to   = $share->file('libtcc.dll');
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    };

    $share->subdir('lib')->mkpath(0, 0755);
    
    foreach my $file ($libdir->subdir('lib')->children)
    {
      my $from = $file;
      my $to   = $share->file('lib', basename $file);
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    }
  }
  else
  {
    my $lib = $libdir->file('libtcc.a');

    die "unable to find libtcc.a" unless -f $lib;

    my $tmp = Path::Class::Dir->new(tempdir( CLEANUP => 1 ));

    do {
      local $CWD = $tmp;
      my $ar = Archive::Ar->new;
      $ar->read($lib->stringify);
      $ar->extract;
    };
    my @obj = grep /\.(o|obj)$/, $tmp->children;

    my @cmd = ($Config{cc}, '-o' => $share->file("libtcc.$Config{dlext}"), '-shared', @obj);

    print "% @cmd\n";
    system @cmd;
  }
}

1;
