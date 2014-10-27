package FFI::TinyCC;

use strict;
use warnings;
use v5.10;
use FFI::Raw;
use File::ShareDir ();
use Config;

# ABSTRACT: Tiny C Compiler for FFI
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

# recent strawberry Perl sets dlext to 'xs.dll'
use constant _dlext => $^O eq 'MSWin32' ? 'dll' : $Config{dlext};

use constant {
  _lib => eval { File::ShareDir::dist_dir('FFI-TinyCC') } ? File::ShareDir::dist_file('FFI-TinyCC', "libtcc." . _dlext) : do {
    require File::Spec;
    require File::Basename;
    File::Spec->rel2abs(
      File::Spec->catfile(
        File::Basename::dirname($INC{'FFI/TinyCC.pm'}),
        File::Spec->updir,
        File::Spec->updir,
        'share',
        'libtcc.' . _dlext,
      ),
    );
  },
  
  # tcc_set_output_type
  _TCC_OUTPUT_MEMORY     => 0,
  _TCC_OUTPUT_EXE        => 1,
  _TCC_OUTPUT_DLL        => 2,
  _TCC_OUTPUT_OBJ        => 3,
  _TCC_OUTPUT_PREPROCESS => 4,

  # tcc_relocate
  _TCC_RELOCATE_AUTO     => 1,
  
  # ??
  _TCC_OUTPUT_FORMAT_ELF    => 0,
  _TCC_OUTPUT_FORMAT_BINARY => 1,
  _TCC_OUTPUT_FORMAT_COFF   => 2,
};

use constant _new => FFI::Raw->new(
  _lib, 'tcc_new',
  FFI::Raw::ptr,
);

use constant _delete => FFI::Raw->new(
  _lib, 'tcc_delete',
  FFI::Raw::void,
  FFI::Raw::ptr,
);

# TODO: tcc_set_error_func

use constant _add_incude_path => FFI::Raw->new(
  _lib, 'tcc_add_include_path',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _add_sysincude_path => FFI::Raw->new(
  _lib, 'tcc_add_sysinclude_path',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _define_symbol => FFI::Raw->new(
  _lib, 'tcc_define_symbol',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::str, FFI::Raw::str,
);

use constant _undefine_symbol => FFI::Raw->new(
  _lib, 'tcc_undefine_symbol',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _add_file => FFI::Raw->new(
  _lib, 'tcc_add_file',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _compile_string => FFI::Raw->new(
  _lib, 'tcc_compile_string',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _set_compile_string => FFI::Raw->new(
  _lib, 'tcc_set_output_type',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::int,
);

use constant _add_library_path => FFI::Raw->new(
  _lib, 'tcc_add_library_path',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::int,
);

use constant _add_library => FFI::Raw->new(
  _lib, 'tcc_add_library',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::int,
);

use constant _add_symbol => FFI::Raw->new(
  _lib, 'tcc_add_symbol',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str, FFI::Raw::ptr,
);

use constant _output_file => FFI::Raw->new(
  _lib, 'tcc_output_file',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _run => FFI::Raw->new(
  _lib, 'tcc_run',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::int, FFI::Raw::ptr,
);

use constant _relocate => FFI::Raw->new(
  _lib, 'tcc_relocate',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::ptr,
);

use constant _get_symbol => FFI::Raw->new(
  _lib, 'tcc_get_symbol',
  FFI::Raw::ptr,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _set_lib_path => FFI::Raw->new(
  _lib, 'tcc_set_lib_path',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::str,
);

=head1 CONSTRUCTOR

=head2 new

 my $tcc = FFI::TinyCC->new;

Create a new TinyCC instance.

=cut

sub new
{
  my($class) = @_;
  bless {
    handle   => _new->call,
    relocate => 0,
  }, $class;
}

sub DESTROY
{
  my($self) = @_;
  _delete->call($self->{handle});
}

=head1 METHODS

Methods will generally throw an exception on failure.

=head2 add_file

 $tcc->add_file('foo.c');
 $tcc->add_file('foo.o');
 $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

=cut

sub add_file
{
  my($self, $filename) = @_;
  my $r = _add_file->call($self->{handle}, $filename);
  # FIXME: dumps core
  # TODO: better diagnostic
  die "unable to add $filename: $!" if $r == -1;
  $self;
}

=head2 compile_string

 $tcc->compile_string($c_code);

Compile a string containing C source code.

=cut

sub compile_string
{
  my($self, $code) = @_;
  my $r = _compile_string->call($self->{handle}, $code);
  # TODO: better diagnostic
  die "unable to compile" if $r == -1;
  $self;
}

=head2 run

 my $exit_value = $tcc->run(@arguments);

=cut

sub run
{
  my($self, @args) = @_;
  die "unable to use run method after get_symbol" if $self->{relocate};
  
  my $argc = scalar @args;
  my @c_strings = map { "$_\0" } @args;
  my $ptrs = pack 'P' x $argc, @c_strings;
  my $argv = unpack('L!', pack('P', $ptrs));

  # TODO: does -1 mean an error?  
  _run->call($self->{handle}, $argc, $argv);
}

=head2 get_symbol

 my $pointer = $tcc->get_symbol($symbol_name);

Return symbol value or undef if not found.  This can be passed into
L<FFI::Raw> or similar for use in your script.

=cut

my $malloc = FFI::Raw->new(
  undef, 'malloc',
  FFI::Raw::ptr,
  FFI::Raw::int,
);

my $free = FFI::Raw->new(
  undef, 'free',
  FFI::Raw::ptr,
);

sub get_symbol
{
  my($self, $symbol_name) = @_;
  
  unless($self->{relocate})
  {
    # FIXME: dumps core
    my $size = _relocate->call($self->{handle}, undef);
    $self->{store} = $malloc->call($size);
    my $r = _relocate->call($self->{handle}, $self->{store});
    # TODO: better diagnostic
    die "unable to relocate" if $r == -1;
    $self->{relocate} = 1;
  }
  _get_symbol->call($self->{handle}, $symbol_name);
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::Raw>

=item L<Alien::TinyCC>

=back

=cut
