package FFI::TinyCC;

use strict;
use warnings;
use 5.008001;
use FFI::Platypus;
use FFI::Platypus::Memory qw( malloc free );
use Carp qw( croak carp );
use File::ShareDir ();

# ABSTRACT: Tiny C Compiler for FFI
# VERSION

=head1 SYNOPSIS

 use FFI::TinyCC;
 use FFI::Platypus::Declare qw( int );
 
 my $tcc = FFI::TinyCC->new;
 
 $tcc->compile_string(q{
   int
   find_square(int value)
   {
     return value*value;
   }
 });
 
 my $address = $tcc->get_symbol('find_square');
 function [$address => 'find_square'] => [int] => int;
 
 print find_square(4), "\n"; # prints 16

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

our $ffi = FFI::Platypus->new;
$ffi->lib(
  $ENV{FFI_TINYCC_LIBTCC_SO} || (eval { File::ShareDir::dist_dir('FFI-TinyCC') } ? File::ShareDir::dist_file('FFI-TinyCC', "libtcc." . _dlext) : do {
    require Path::Class::File;
    Path::Class::File
      ->new($INC{'FFI/TinyCC.pm'})
      ->dir
      ->parent
      ->parent
      ->file('share', 'libtcc.' . _dlext)
      ->stringify
  }
));

$ffi->custom_type( tcc_t => {
  perl_to_native => sub {
    $_[0]->{handle},
  },
  
  native_to_perl => sub {
    {
      handle   => $_[0],
      relocate => 0,
      error    => [],
    };
  },

});

do {
  my %output_type = qw(
    memory 0
    exe    1
    dll    2
    obj    3
  );

  $ffi->custom_type( output_t => {
    native_type => 'int',
    perl_to_native => sub { $output_type{$_[0]} },
  });
};

$ffi->type('int' => 'error_t');
$ffi->type('(opaque,string)->void' => 'error_handler_t');

$ffi->attach([tcc_new             => '_new']             => []                                     => 'tcc_t');
$ffi->attach([tcc_delete          => '_delete']          => ['tcc_t']                              => 'void');
$ffi->attach([tcc_set_error_func  => '_set_error_func']  => ['tcc_t', 'opaque', 'error_handler_t'] => 'void');
$ffi->attach([tcc_add_symbol      => '_add_symbol']      => ['tcc_t', 'string', 'opaque']          => 'int');
$ffi->attach([tcc_get_symbol      => '_get_symbol']      => ['tcc_t', 'string']                    => 'opaque');
$ffi->attach([tcc_relocate        => '_relocate']        => ['tcc_t', 'opaque']                    => 'int');
$ffi->attach([tcc_run             => '_run']             => ['tcc_t', 'int', 'opaque']             => 'int');

sub _method ($;@)
{
  my($name, @args) = @_;
  $ffi->attach(["tcc_$name" => "_$name"] => ['tcc_t', @args] => 'error_t');
  eval  '# line '. __LINE__ . ' "' . __FILE__ . qq("\n) .qq{
    sub $name
    {
      my \$r = _$name (\@_);
      die FFI::TinyCC::Exception->new(\$_[0]) if \$r == -1;
      \$_[0];
    }
  };
  die $@ if $@;
}

=head1 CONSTRUCTOR

=head2 new

 my $tcc = FFI::TinyCC->new;

Create a new TinyCC instance.

=cut

sub new
{
  my($class, %opt) = @_;

  my $self = bless _new(), $class;
  
  $self->{error_cb} = $ffi->closure(sub {
    push @{ $self->{error} }, $_[1];
  });
  _set_error_func($self, undef, $self->{error_cb});
  
  if($^O eq 'MSWin32')
  {
    require File::Basename;
    require File::Spec;
    my $path = File::Spec->catdir(File::Basename::dirname($ffi->lib), 'lib');
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

_method set_options => qw( string );

=head3 add_file

 $tcc->add_file('foo.c');
 $tcc->add_file('foo.o');
 $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

On windows adding a DLL is not supported via this interface.

=cut

_method add_file => qw( string );

=head3 compile_string

 $tcc->compile_string($c_code);

Compile a string containing C source code.

=cut

_method compile_string => qw( string );

=head3 add_symbol

 $tcc->add_symbol($name, $callback);
 $tcc->add_symbol($name, $pointer);

Add the given given symbol name / callback or pointer combination.
See example below for how to use this to call Perl from Tiny C code.

It will accept a L<FFI::Raw::Callback> at a performance penalty.
If possible pass in the pointer to the C entry point instead.

If you are using L<FFI::Platypus> you can use L<FFI::Platypus#cast>
or L<FFI::Platypus::Declare#cast> to get a pointer to a closure:

 use FFI::Platypus::Declare;
 my $clousre = closure { return $_[0]+1 };
 my $pointer = cast '(int)->int' => 'opaque', $closure;
 
 $tcc->add_symbol('foo' => $pointer);

=cut

sub add_symbol
{
  my($self, $name, $ptr) = @_;
  my $r;
  if(ref($ptr) && eval { $ptr->isa('FFI::Raw::Callback') })
  {
    require FFI::Raw;
    my($lib) = $ffi->lib;
    my $add_symbol = FFI::Raw->new($lib, 'tcc_add_symbol',
      FFI::Raw::int(),
      FFI::Raw::ptr(), FFI::Raw::str(), FFI::Raw::ptr(),
    );
    $r = $add_symbol->call($self->{handle}, $name, $ptr);
  }
  else
  {
    $r = _add_symbol($self, $name, $ptr);
  }
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $self;
}

=head2 Preprocessor options

=head3 add_include_path

 $tcc->add_include_path($path);

Add the given path to the list of paths used to search for include files.

=cut

_method add_include_path => qw( string );

=head3 add_sysinclude_path

 $tcc->add_sysinclude_path($path);

Add the given path to the list of paths used to search for system include files.

=cut

_method add_sysinclude_path => qw( string );

=head3 set_lib_path

 $tcc->set_lib_path($path);

Set the lib path

=cut

_method set_lib_path => qw( string );

=head3 define_symbol

 $tcc->define_symbol($name => $value);
 $tcc->define_symbol($name);

Define the given symbol, optionally with the specified value.

=cut

$ffi->attach([tcc_define_symbol=>'define_symbol'] => ['tcc_t', 'string', 'string'] => 'void');

=head3 undefine_symbol

 $tcc->undefine_symbol($name);

Undefine the given symbol.

=cut

$ffi->attach([tcc_undefine_symbol=>'undefine_symbol'] => ['tcc_t', 'string', 'string'] => 'void');

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

_method set_output_type => qw( output_t );

=head3 add_library

 $tcc->add_library($libname);

Add the given library when linking.  Example:

 $tcc->add_library('m'); # equivalent to -lm (math library)

=cut

_method add_library => qw( string );

=head3 add_library_path

 $tcc->add_library_path($pathname);

Add the given directory to the search path used to find libraries.

=cut

_method add_library_path => qw( string );

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

  my $r = _run($self, $argc, $argv);
  die FFI::TinyCC::Exception->new($self) if $r == -1;
  $r;  
}

=head3 get_symbol

 my $pointer = $tcc->get_symbol($symbol_name);

Return symbol address or undef if not found.  This can be passed into
the L<FFI::Platypus#function> method, L<FFI::Platypus#attach> method,
L<FFI::Platypus::Declare#function> function or similar interface that
takes a pointer to a C function.

=cut

sub get_symbol
{
  my($self, $symbol_name) = @_;
  
  unless($self->{relocate})
  {
    my $size = _relocate($self, undef);
    $self->{store} = malloc($size);
    my $r = _relocate($self, $self->{store});
    FFI::TinyCC::Exception->new($self) if $r == -1;
    $self->{relocate} = 1;
  }
  _get_symbol($self, $symbol_name);
}

=head3 output_file

 $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the given filename.
The type of output is specified by the L<set_output_type|FFI::TinyCC#set_output_type>
method.

=cut

_method output_file => qw( string );

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

Or better yet, use L<FFI::Platypus> instead.

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
  require FFI::Raw;
  FFI::Raw->new_from_ptr($self->get_symbol($symbol), @types);
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

=head2 Attaching as a FFI::Platypus function from a Tiny C function

# EXAMPLE: example/ffi_platypus.pl

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

=item L<FFI::Platypus>

=item L<Alien::TinyCC>

=item L<C::TinyCompiler>

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
