package FFI::TinyCC::Inline;

use strict;
use warnings;
use v5.10;
use FFI::TinyCC;
use FFI::TinyCC::Parser;
use FFI::Raw;
use Carp qw( croak );
use base qw( Exporter );

our @EXPORT_OK = qw( tcc_inline tcc_eval );
our @EXPORT = @EXPORT_OK;

# ABSTRACT: Embed Tiny C code in your Perl program
# VERSION

=head1 SYNOPSIS

 use FFI::TinyCC::Inline qw( tcc_inline );
 
 tcc_inline q{
   int square(int num)
   {
     return num*num;
   }
 };
 
 say square(4); # prints 16

 use FFI::TinyCC::Inline qw( tcc_eval );
 
 # sets value to 6:
 my $value = tcc_eval q{
   int main(int a, int b, int c)
   {
     return a + b + c;
   }
 }, 1, 2, 3;

=head1 DESCRIPTION

This module provides a simplified interface to FFI::TinyCC, that allows you
to write Perl subs in C.  It is inspired by L<XS::TCC>, but it uses L<FFI::Raw>
to create bindings instead of XS.

=cut

my %typemap = (
  'int'            => FFI::Raw::int,
  'signed int'     => FFI::Raw::int,
  'unsigned int'   => FFI::Raw::uint,
  'void'           => FFI::Raw::void,
  'short'          => FFI::Raw::short,
  'signed short'   => FFI::Raw::short,
  'unsigned short' => FFI::Raw::ushort,
  'long'           => FFI::Raw::long,
  'signed long'    => FFI::Raw::long,
  'unsigned long'  => FFI::Raw::ulong,
  'char'           => FFI::Raw::char,
  'signed char'    => FFI::Raw::char,
  'unsigned char'  => FFI::Raw::uchar,
  'float'          => FFI::Raw::float,
  'double'         => FFI::Raw::double,
  'char *'         => FFI::Raw::str,
);

sub _typemap ($)
{
  my($type) = @_;
  $type =~ s{^const }{};
  return $typemap{$type}
    if defined $typemap{$type};
  return FFI::Raw::ptr if $type =~ /\*$/;
  croak "unknown type: $type";
}

sub _generate_sub ($$$)
{
  my($func_name, $func, $tcc) = @_;
  my $sub;
  
  if(@{ $func->{arg_types} } == 2
  && $func->{arg_types}->[0] eq 'int'
  && $func->{arg_types}->[1] =~ /^(const |)char \*\*$/)
  {
    my $ffi = $tcc->get_ffi_raw($func_name, _typemap $func->{return_type}, FFI::Raw::int, FFI::Raw::ptr);
    $sub = sub {
      my $argc = scalar @_;
      my @c_strings = map { "$_\0" } @_;
      my $ptrs = pack 'P' x $argc, @c_strings;
      my $argv = unpack 'L!', pack 'P', $ptrs;
      $ffi->call($argc, $argv);
    };
  }
  else
  {
    my @types = map { _typemap $_ } ($func->{return_type}, @{ $func->{arg_types} });
    my $ffi = $tcc->get_ffi_raw($func_name, @types);
    no strict 'refs';
    $sub = sub { $ffi->call(@_) };
  }
  
  $sub;
}

=head1 OPTIONS

You can specify tcc options using the scoped pragmata, like so:

 use FFI::TinyCC::Inline options => "-I/foo/include -L/foo/lib -DFOO=1";
 
 # prints 1
 say tcc_eval q{
 #include <foo.h> /* will search /foo/include
 int main()
 {
   return FOO; /* defined and set to 1 */
 }
 };

=cut

sub import
{
  my($class, @rest) = @_;
  
  if(defined $rest[0] && defined $rest[1]
  && $rest[0] eq 'options')
  {
    shift @rest;
    $^H{"FFI::TinyCC::Inline/options"} = shift @rest;
  }
  
  return unless @rest > 0;

  @_ = ($class, @rest);
  goto &Exporter::import;
}

=head1 FUNCTIONS

=head2 tcc_inline

 tcc_inline $c_code;

Compile the given C code using Tiny C and inject any functions found into the
current package.  An exception will be thrown if the code fails to compile, or if
L<FFI::TinyCC::Inline> does not recognize one of the argument or return
types.

 tcc_inline q{
   int foo(int a, int b, int c)
   {
     return a + b + c;
   }
 };
 
 say foo(1,2,3); # prints 6

The special argument type of C<(int argc, char **argv)> is recognized and
will be translated from the list of arguments passed in.  Example:

 tcc_inline q{
   void foo(int argc, const char **argv)
   {
     int i;
     for(i=0; i<argc; i++)
     {
       puts(argv[i]);
     } 
   }
 };
 
 foo("one", "two", "three"); # prints "one\ntwo\nthree\n"

=cut

sub tcc_inline ($)
{
  my($code) = @_;
  my $caller = caller;
  
  my $tcc = FFI::TinyCC->new(_no_free_store => 1);
  
  my $h = (caller(0))[10];
  if($h->{"FFI::TinyCC::Inline/options"})
  { $tcc->set_options($h->{"FFI::TinyCC::Inline/options"}) }

  $tcc->compile_string($code);
  my $meta = FFI::TinyCC::Parser->extract_function_metadata($code);
  foreach my $func_name (keys %{ $meta->{functions} })
  {
    my $sub = _generate_sub($func_name, $meta->{functions}->{$func_name}, $tcc);
    no strict 'refs';
    *{join '::', $caller, $func_name} = $sub;
  }
  ();
}

=head2 tcc_eval

 tcc_eval $c_code, @arguments;

This compiles the C code and executes the C<main> function, passing in the given arguments.
Returns the result.

=cut

sub tcc_eval ($;@)
{
  my($code, @args) = @_;
  my $tcc = FFI::TinyCC->new;
  
  my $h = (caller(0))[10];
  if($h->{"FFI::TinyCC::Inline/options"})
  { $tcc->set_options($h->{"FFI::TinyCC::Inline/options"}) }

  $tcc->compile_string($code);
  my $meta = FFI::TinyCC::Parser->extract_function_metadata($code);
  my $func = $meta->{functions}->{main};
  croak "no main function" unless defined $func;
  my $sub = _generate_sub('main', $meta->{functions}->{main}, $tcc);
  $sub->(@args);
}

1;

=head1 SEE ALSO

=over 4

=item L<FFI::TinyCC>

=back

=cut
