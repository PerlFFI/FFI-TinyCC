package FFI::TinyCC;

use strict;
use warnings;
use 5.010;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );
use FFI::Raw;
use Carp qw( croak carp );
use File::ShareDir ();

# ABSTRACT: Tiny C Compiler for FFI
# VERSION

=head1 SYNOPSIS

 use FFI::TinyCC;
 use FFI::Raw;
 
 my $tcc = FFI::TinyCC->new;
 
 $tcc->compile_string(q{
   int
   find_square(int value)
   {
     return value*value;
   }
 });
 
 my $find_square = FFI::Raw->new_from_ptr(
   $tcc->get_symbol('find_square'),
   FFI::Raw::int,  # return type
   FFI::Raw::int,  # argument types
 );
 
 # $find_square isa FFI::Raw
 say $find_square->call(4); # says 16

=head1 DESCRIPTION

This module provides an interface to a very small C compiler known as
TinyCC.  It does almost no optimizations, so C<gcc> or C<clang> will
probably generate faster code, but it is very small and is very fast
and thus may be useful for some Just In Time (JIT) or Foreign Function
Interface (FFI) situations.

For a simpler, but less powerful interface see L<FFI::TinyCC::Inline>.

=cut

sub _dlext
{
  require Config;
  # recent strawberry Perl sets dlext to 'xs.dll'
  $^O eq 'MSWin32' ? 'dll' : $Config::Config{dlext};
}

use constant {
  _lib => $ENV{FFI_TINYCC_LIBTCC_SO} // (eval { File::ShareDir::dist_dir('FFI-TinyCC') } ? File::ShareDir::dist_file('FFI-TinyCC', "libtcc." . _dlext) : do {
    require Path::Class::File;
    Path::Class::File
      ->new($INC{'FFI/TinyCC.pm'})
      ->dir
      ->parent
      ->parent
      ->file('share', 'libtcc.' . _dlext)
      ->stringify
  }),
  
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

my $ffi = FFI::Platypus->new;
$ffi->lib(_lib);

$ffi->custom_type( opaque => tcc_t => {
  perl_to_ffi => sub {
    $_[0]->{handle},
  },
  
  ffi_to_perl => sub {
    {
      handle   => $_[0],
      relocate => 0,
      error    => [],
    };
  },

});

$ffi->attach([tcc_new    => '_new'] => [] => 'tcc_t');
$ffi->attach([tcc_delete => '_delete'] => ['tcc_t'] => 'void');

use constant _set_error_func => FFI::Raw->new(
  _lib, 'tcc_set_error_func',
  FFI::Raw::void,
  FFI::Raw::ptr, FFI::Raw::ptr, FFI::Raw::ptr,
);

use constant _set_options => FFI::Raw->new(
  _lib, 'tcc_set_options',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _add_include_path => FFI::Raw->new(
  _lib, 'tcc_add_include_path',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _add_sysinclude_path => FFI::Raw->new(
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

$ffi->attach([tcc_add_file => '_add_file'] => ['tcc_t','string'] => 'int');

use constant _compile_string => FFI::Raw->new(
  _lib, 'tcc_compile_string',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _set_output_type => FFI::Raw->new(
  _lib, 'tcc_set_output_type',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::int,
);

use constant _add_library_path => FFI::Raw->new(
  _lib, 'tcc_add_library_path',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
);

use constant _add_library => FFI::Raw->new(
  _lib, 'tcc_add_library',
  FFI::Raw::int,
  FFI::Raw::ptr, FFI::Raw::str,
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
  my($class, %opt) = @_;

  my $self = bless _new(), $class;
  
  $self->{error_cb} = FFI::Raw::Callback->new(
    sub { push @{ $self->{error} }, $_[1] },
    FFI::Raw::void,
    FFI::Raw::ptr, FFI::Raw::str,
  );
  
  _set_error_func->call($self->{handle}, undef, $self->{error_cb});
  
  if($^O eq 'MSWin32')
  {
    require File::Basename;
    require File::Spec;
    my $path = File::Spec->catdir(File::Basename::dirname(_lib), 'lib');
    $self->add_library_path($path);
  }
  
  $self->{no_free_store} = 1 if $opt{_no_free_store};
  
  $self;
}

sub _error
{
  my($self, $msg) = @_;
  push @{ $self->{error} }, $msg;
  $self;
}

if(defined ${^GLOBAL_PHASE})
{
  *DESTROY = sub
  {
    my($self) = @_;
    return if ${^GLOBAL_PHASE} eq 'DESTRUCT';
    _delete($self);
    # TODO: should we do this?
    free($self->{store});
  }
}
else
{
  require Devel::GlobalDestruction;
  *DESTROY = sub
  {
    my($self) = @_;
    return if Devel::GlobalDestruction::in_global_destruction();
    _delete($self);
    # TODO: should we do this?
    free($self->{store});
  }
}

=head1 METHODS

Methods will generally throw an exception on failure.

=head2 Compile

=head3 set_options

 $tcc->set_options($options);

Set compiler and linker options, as you would on the command line, for example:

 $tcc->set_options('-I/foo/include -L/foo/lib -DFOO=22');

=cut

sub set_options
{
  my($self, $options) = @_;
  my $r = _set_options->call($self->{handle}, $options);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head3 add_file

 $tcc->add_file('foo.c');
 $tcc->add_file('foo.o');
 $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

On windows adding a DLL is not supported via this interface.

=cut

sub add_file
{
  my($self, $filename) = @_;
  my $r = _add_file($self, $filename);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head3 compile_string

 $tcc->compile_string($c_code);

Compile a string containing C source code.

=cut

sub compile_string
{
  my($self, $code) = @_;
  my $r = _compile_string->call($self->{handle}, $code);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head3 add_symbol

 $tcc->add_symbol($name, $callback);
 $tcc->add_symbol($name, $pointer);

Add the given given symbol name / callback or pointer combination.
See example below for how to use this to call Perl from Tiny C code.

=cut

sub add_symbol
{
  my($self, $name, $ptr) = @_;
  my $r = _add_symbol->call($self->{handle}, $name, $ptr);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head2 Preprocessor options

=head3 add_include_path

 $tcc->add_include_path($path);

Add the given path to the list of paths used to search for include files.

=cut

sub add_include_path
{
  my($self, $path) = @_;
  _add_include_path->call($self->{handle}, $path);
  $self;
}

=head3 add_sysinclude_path

 $tcc->add_sysinclude_path($path);

Add the given path to the list of paths used to search for system include files.

=cut

sub add_sysinclude_path
{
  my($self, $path) = @_;
  _add_sysinclude_path->call($self->{handle}, $path);
  $self;
}

=head3 define_symbol

 $tcc->define_symbol($name => $value);
 $tcc->define_symbol($name);

Define the given symbol, optionally with the specified value.

=cut

sub define_symbol
{
  my($self, $name, $value) = @_;
  _define_symbol->call($self->{handle}, $name, $value);
  $self;
}

=head3 undefine_symbol

 $tcc->undefine_symbol($name);

Undefine the given symbol.

=cut

sub undefine_symbol
{
  my($self, $name) = @_;
  _undefine_symbol->call($self->{handle}, $name);
  $self;
}

=head2 Link / run

=head3 set_output_type

 $tcc->set_output_type('memory');
 $tcc->set_output_type('exe');
 $tcc->set_output_type('dll');
 $tcc->set_output_type('obj');

Set the output type.  This must be called before any compilation.

Output formats may not be supported on your platform.  C<exe> is
NOT supported on *BSD or OS X.

As a basic baseline at least C<memory> should be supported.

=cut

my %output_type = (
  memory => 0,
  exe    => 1,
  dll    => 2,
  obj    => 3,
);

sub set_output_type
{
  my($self, $type) = @_;
  croak "unknown type: $type" unless defined $output_type{$type};
  _set_output_type->call($self->{handle}, $output_type{$type});
  $self;
}

=head3 add_library

 $tcc->add_library($libname);

Add the given library when linking.  Example:

 $tcc->add_library('m'); # equivalent to -lm (math library)

=cut

sub add_library
{
  my($self, $libname) = @_;
  my $r = _add_library->call($self->{handle}, $libname);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head3 add_library_path

 $tcc->add_library_path($pathname);

Add the given directory to the search path used to find libraries.

=cut

sub add_library_path
{
  my($self, $pathname) = @_;
  my $r = _add_library_path->call($self->{handle}, $pathname);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;  
}

=head3 run

 my $exit_value = $tcc->run(@arguments);

=cut

sub run
{
  my($self, @args) = @_;
  
  croak "unable to use run method after get_symbol" if $self->{relocate};
  
  my $argc = scalar @args;
  my @c_strings = map { "$_\0" } @args;
  my $ptrs = pack 'P' x $argc, @c_strings;
  my $argv = unpack('L!', pack('P', $ptrs));

  my $r = _run->call($self->{handle}, $argc, $argv);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $r;  
}

=head3 get_symbol

 my $pointer = $tcc->get_symbol($symbol_name);

Return symbol value or undef if not found.  This can be passed into
L<FFI::Raw> or similar for use in your script.

=cut

sub get_symbol
{
  my($self, $symbol_name) = @_;
  
  unless($self->{relocate})
  {
    my $size = _relocate->call($self->{handle}, undef);
    $self->{store} = malloc($size);
    my $r = _relocate->call($self->{handle}, $self->{store});
    FFI::TinyCC::Exception->new($self) if $r == -1;
    $self->{relocate} = 1;
  }
  _get_symbol->call($self->{handle}, $symbol_name);
}

=head3 get_ffi_raw

B<DEPRECATED>

 my $ffi = $tcc->get_ffi_raw($symbol_name, $return_type, @argument_types);

Given the name of a function, return an L<FFI::Raw> instance that will allow you to call it from Perl.

This method is deprecated, and will be removed from a future version of
L<FFI::TinyCC>.  It will issue a warning if you try to use it.  Instead
of this:

 my $function = $ffi->get_ffi_raw($name, $ret, @args);

Do this:

 use FFI::Raw;
 my $function = FFI::Raw->new_from_ptr($ffi->get_symbol($name), $ret, @args);

Also, L<FFI::Raw> will be replaced as a prerequisite in an upcoming version
of L<FFI::TinyCC>, so make sure that you C<use FFI::Raw> if you are using
it.

=cut

# this variable will too be removed once this module
# is ported to FFI::Platypus, so do not depeend on it!
our $_get_ffi_raw_deprecation = 1;

sub get_ffi_raw
{
  carp "FFI::TinyCC->get_ffi_raw is deprecated" if $_get_ffi_raw_deprecation;
  my($self, $symbol, @types) = @_;
  croak "you must at least specify a return type" unless @types > 0;
  my $ptr = $self->get_symbol($symbol);
  croak "$symbol not found" unless $ptr;
  FFI::Raw->new_from_ptr($self->get_symbol($symbol), @types);
}

=head3 output_file

 $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the given filename.
The type of output is specified by the L<set_output_type|FFI::TinyCC#set_output_type>
method.

=cut

sub output_file
{
  my($self, $filename) = @_;
  my $r = _output_file->call($self->{handle}, $filename);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

package
  FFI::TinyCC::Exception;

use overload '""' => sub {
  my $self = shift;
  if(@{ $self->{fault} } == 2)
  {
    join(' ', $self->as_string, 
      at => $self->{fault}->[0], 
      line => $self->{fault}->[1],
    );
  }
  else
  {
    $self->as_string . "\n";
  }
};
use overload fallback => 1;

sub new
{
  my($class, $tcc) = @_;
  
  my @errors = @{ $tcc->{error} };
  $tcc->{errors} = [];
  my @stack;
  my @fault;
  
  my $i=2;
  while(my @frame = caller($i++))
  {
    push @stack, \@frame;
    if(@fault == 0 && $frame[0] !~ /^FFI::TinyCC/)
    {
      @fault = ($frame[1], $frame[2]);
    }
  }
  
  my $self = bless {
    errors => \@errors,
    stack  => \@stack,
    fault  => \@fault,
  }, $class;
  
  $self;
}

sub errors { shift->{errors} }

sub as_string
{
  my($self) = @_;
  join "\n", @{ $self->{errors} };
}

1;

=head1 EXAMPLES

=head2 Calling Tiny C code from Perl

# EXAMPLE: example/hello.pl

=head2 Calling Perl from Tiny C code

# EXAMPLE: example/callback.pl

=head2 Creating a FFI::Raw handle from a Tiny C function

# EXAMPLE: example/ffi.pl

=head1 CAVEATS

Tiny C is only supported on platforms with ARM or Intel processors.  All features may not be fully supported on
all operating systems.

Tiny C is no longer supported by its original author, though various forks seem to have varying levels of support.
We use the fork that comes with L<Alien::TinyCC>.

=head1 SEE ALSO

=over 4

=item L<FFI::TinyCC::Inline>

=item L<Tiny C|http://bellard.org/tcc/>

=item L<Tiny C Compiler Reference Documentation|http://bellard.org/tcc/tcc-doc.html>

=item L<FFI::Raw>

=item L<Alien::TinyCC>

=back

=head1 BUNDLED SOFTWARE

This package also comes with a parser that was shamelessly stolen from L<XS::TCC>,
which I strongly suspect was itself shamelessly "borrowed" from 
L<Inline::C::Parser::RegExp>

The license details for the parser are:

Copyright 2002 Brian Ingerson
Copyright 2008, 2010-2012 Sisyphus
Copyright 2013 Steffen Muellero

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
