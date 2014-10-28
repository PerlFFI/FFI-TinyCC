# FFI::TinyCC

Tiny C Compiler for FFI

# SYNOPSIS

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
    
    my $find_square = $tcc->get_ffi_raw(
      'find_square',
      FFI::Raw::int,  # return type
      FFI::Raw::int,  # argument types
    );
    
    # $find_square isa FFI::Raw
    say $find_square->call(4); # says 16

# DESCRIPTION

This module provides an interface to a very small C compiler known as
TinyCC.  It does almost no optimizations, so `gcc` or `clang` will
probably generate faster code, but it is very small and is very fast
and thus may be useful for some Just In Time (JIT) or Foreign Function
Interface (FFI) situations.

For a simpler, but less powerful interface see [FFI::TinyCC::Inline](https://metacpan.org/pod/FFI::TinyCC::Inline).

# CONSTRUCTOR

## new

    my $tcc = FFI::TinyCC->new;

Create a new TinyCC instance.

# METHODS

Methods will generally throw an exception on failure.

## Compile

### set\_options

    $tcc->set_options($options);

Set compiler and linker options, as you would on the command line, for example:

    $tcc->set_options('-I/foo/include -L/foo/lib -DFOO=22');

### add\_file

    $tcc->add_file('foo.c');
    $tcc->add_file('foo.o');
    $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

On windows adding a DLL is not supported via this interface.

### compile\_string

    $tcc->compile_string($c_code);

Compile a string containing C source code.

### add\_symbol

    $tcc->add_symbol($name, $callback);
    $tcc->add_symbol($name, $pointer);

Add the given given symbol name / callback or pointer combination.
See example below for how to use this to call Perl from Tiny C code.

## Preprocessor options

### add\_include\_path

    $tcc->add_include_path($path);

Add the given path to the list of paths used to search for include files.

### add\_sysinclude\_path

    $tcc->add_sysinclude_path($path);

Add the given path to the list of paths used to search for system include files.

### define\_symbol

    $tcc->define_symbol($name => $value);
    $tcc->define_symbol($name);

Define the given symbol, optionally with the specified value.

### undefine\_symbol

    $tcc->undefine_symbol($name);

Undefine the given symbol.

## Link / run

### set\_output\_type

    $tcc->set_output_type('memory');
    $tcc->set_output_type('exe');
    $tcc->set_output_type('dll');
    $tcc->set_output_type('obj');

Set the output type.  This must be called before any compilation.

### add\_library

    $tcc->add_library($libname);

Add the given library when linking.  Example:

    $tcc->add_library('m'); # equivalent to -lm (math library)

### add\_library\_path

    $tcc->add_library_path($pathname);

Add the given directory to the search path used to find libraries.

### run

    my $exit_value = $tcc->run(@arguments);

### get\_symbol

    my $pointer = $tcc->get_symbol($symbol_name);

Return symbol value or undef if not found.  This can be passed into
[FFI::Raw](https://metacpan.org/pod/FFI::Raw) or similar for use in your script.

### get\_ffi\_raw

    my $ffi = $tcc->get_ffi_raw($symbol_name, $return_type, @argument_types);

Given the name of a function, return an [FFI::Raw](https://metacpan.org/pod/FFI::Raw) instance that will allow you to call it from Perl.

### output\_file

    $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the given filename.
The type of output is specified by the [set\_output\_type](https://metacpan.org/pod/FFI::TinyCC#set_output_type)
method.

# EXAMPLES

## Calling Tiny C code from Perl

    use strict;
    use warnings;
    use v5.10;
    use FFI::TinyCC;
    use FFI::Raw;
    
    my $tcc = FFI::TinyCC->new;
    
    $tcc->compile_string(<<EOF);
    int
    main(int argc, char *argv[])
    {
      puts("hello world");
    }
    EOF
    
    my $r = $tcc->run;
    
    exit $r;

## Calling Perl from Tiny C code

    use strict;
    use warnings;
    use v5.10;
    use FFI::TinyCC;
    use FFI::Raw;
    
    my $say = FFI::Raw::Callback->new(
      sub { say $_[0] },
      FFI::Raw::void,
      FFI::Raw::str,
    );
    
    my $tcc = FFI::TinyCC->new;
    
    $tcc->add_symbol(say => $say);
    
    $tcc->compile_string(q{
    extern void say(const char *);
    
    int
    main(int argc, char *argv[])
    {
      int i;
      for(i=1; i<argc; i++)
      {
        say(argv[i]);
      }
    }
    });
    
    # use '-' for the program name
    my $r = $tcc->run('-', @ARGV);
    
    exit $r;

## Creating a FFI::Raw handle from a Tiny C function

    use strict;
    use warnings;
    use v5.10;
    use FFI::TinyCC;
    use FFI::Raw;
    
    my $tcc = FFI::TinyCC->new;
    
    $tcc->compile_string(q{
      int
      calculate_square(int value)
      {
        return value*value;
      }
    });
    
    my $value = (shift @ARGV) // 4;
    
    # $square isa FFI::Raw
    my $square = $tcc->get_ffi_raw(
      'calculate_square',
      FFI::Raw::int,  # return type
      FFI::Raw::int,  # argument types
    );
    
    say $square->call($value);

# BUNDLED SOFTWARE

This package also comes with a parser that was shamelessly stolen from [XS::TCC](https://metacpan.org/pod/XS::TCC),
itself borrowed which I strongly suspect was itself shamelessly "borrowed"
from [Inline::C::Parser::RegExp](https://metacpan.org/pod/Inline::C::Parser::RegExp)

The license details for the parser are:

Copyright 2002 Brian Ingerson
Copyright 2008, 2010-2012 Sisyphus
Copyright 2013 Steffen Muellero

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

# SEE ALSO

- [FFI::TinyCC::Inline](https://metacpan.org/pod/FFI::TinyCC::Inline)
- [Tiny C](http://bellard.org/tcc/)
- [Tiny C Compiler Reference Documentation](http://bellard.org/tcc/tcc-doc.html)
- [FFI::Raw](https://metacpan.org/pod/FFI::Raw)
- [Alien::TinyCC](https://metacpan.org/pod/Alien::TinyCC)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
