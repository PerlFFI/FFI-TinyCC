package My::DLL;

use strict;
use warnings;
use 5.010;
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

my $log = $share->file('build.log')->opena;

sub tcc_clean
{
  say $log "--- clean ", time, '---';
  for(grep { $_->basename =~ /^libtcc\./ } $share->children)
  {
    say $log "unlink $_";
    unlink $_;
  }
  if(-d $share->subdir('lib'))
  {
    for($share->subdir('lib')->children)
    {
      say $log "unlink $_";
      unlink $_;
    }
    say $log "rmdir " . $share->subdir('lib');
    rmdir $share->subdir('lib');
  }
}

sub tcc_build
{
  tcc_clean();
  
  say $log "--- build ", time, '---';

  my $libdir = Path::Class::Dir->new(
    Alien::TinyCC->libtcc_library_path,
  )->absolute;

  if($^O eq 'MSWin32')
  {
    do {
      my $from = $libdir->file('libtcc.dll');
      my $to   = $share->file('libtcc.dll');
      say $log "copy $from => $to";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    };

    $share->subdir('lib')->mkpath(0, 0755);
    
    foreach my $file ($libdir->subdir('lib')->children)
    {
      my $from = $file;
      my $to   = $share->file('lib', basename $file);
      say $log "copy $from $to";
      copy($from => $to)
      || die "unable to copy $from => $to $!";
    }
  }
  else
  {
    my $lib = $libdir->file('libtcc.a');
    say $log "lib = $lib";

    die "unable to find libtcc.a" unless -f $lib;

    my $tmp = Path::Class::Dir->new(tempdir( CLEANUP => 1 ));
    say $log "tmp = $tmp";

    do {
      local $CWD = $tmp;
      my $ar = Archive::Ar->new;
      $ar->read($lib->stringify);
      foreach my $old ($ar->list_files)
      {
        my $new = $old;
        $new =~ s{\0+$}{};
        next if $new eq $old;
        $ar->rename($old, $new);
      }
      $ar->extract || die $ar->error;
    };
    my @obj = grep /\.(o|obj)$/, $tmp->children;
    say $log "obj = $_" for @obj;

    my @cmd = ($Config{cc}, '-o' => $share->file("libtcc.$Config{dlext}"), '-shared', @obj);
    say $log "+ @cmd\n";

    print "+ @cmd\n";
    system @cmd;
    die if $?;
  }
}

1;
