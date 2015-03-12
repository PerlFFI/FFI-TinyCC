# FFI::TinyCC

Tiny C Compiler for FFI

# SYNOPSIS

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
    attach [$address => 'find_square'] => [int] => int;
    
    print find_square(4), "\n"; # prints 16

For code that requires system headers:

    use FFI::TinyCC;
    use FFI::Platypus::Declare qw( void );
    
    my $tcc = FFI::TinyCC->new;
    
    # this will throw an exception if the system
    # include paths cannot be detected.
    $tcc->detect_sysinclude_path;
    
    $tcc->compile_string(q{
      #include <stdio.h>
      
      void print_hello()
      {
        puts("hello world");
      }
    });
    
    my $address = $tcc->get_symbol('print_hello');
    attach [$address => 'print_hello'] => [] => void;
    print_hello();

# DESCRIPTION

This module provides an interface to a very small C compiler known as 
TinyCC.  It does almost no optimizations, so `gcc` or `clang` will 
probably generate faster code, but it is very small and is very fast and 
thus may be useful for some Just In Time (JIT) or Foreign Function 
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

Set compiler and linker options, as you would on the command line, for 
example:

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

Add the given given symbol name / callback or pointer combination. See 
example below for how to use this to call Perl from Tiny C code.

It will accept a [FFI::Raw::Callback](https://metacpan.org/pod/FFI::Raw::Callback) at a performance penalty. If 
possible pass in the pointer to the C entry point instead.

If you are using [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) you can use [FFI::Platypus#cast](https://metacpan.org/pod/FFI::Platypus#cast) or 
[FFI::Platypus::Declare#cast](https://metacpan.org/pod/FFI::Platypus::Declare#cast) to get a pointer to a closure:

    use FFI::Platypus::Declare;
    my $clousre = closure { return $_[0]+1 };
    my $pointer = cast '(int)->int' => 'opaque', $closure;
    
    $tcc->add_symbol('foo' => $pointer);

## Preprocessor options

### detect\_sysinclude\_path

\[version 0.18\]

    $tcc->detect_sysinclude_path;

Attempt to find and configure the appropriate system include directories. If 
the platform that you are on does not (yet?) support this functionality 
then this method will throw an exception.

\[version 0.19\]

Returns the list of directories added to the system include directories.

### add\_include\_path

    $tcc->add_include_path($path);

Add the given path to the list of paths used to search for include files.

### add\_sysinclude\_path

    $tcc->add_sysinclude_path($path);

Add the given path to the list of paths used to search for system 
include files.

### set\_lib\_path

    $tcc->set_lib_path($path);

Set the lib path

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

Output formats may not be supported on your platform.  `exe` is
NOT supported on \*BSD or OS X.

As a basic baseline at least `memory` should be supported.

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

Return symbol address or undef if not found.  This can be passed into 
the [FFI::Platypus#function](https://metacpan.org/pod/FFI::Platypus#function) method, [FFI::Platypus#attach](https://metacpan.org/pod/FFI::Platypus#attach) method, 
[FFI::Platypus::Declare#function](https://metacpan.org/pod/FFI::Platypus::Declare#function) function or similar interface that 
takes a pointer to a C function.

### output\_file

    $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the 
given filename. The type of output is specified by the 
[set\_output\_type](#set_output_type) method.

### get\_ffi\_raw

**DEPRECATED**

    my $ffi = $tcc->get_ffi_raw($symbol_name, $return_type, @argument_types);

Given the name of a function, return an [FFI::Raw](https://metacpan.org/pod/FFI::Raw) instance that will 
allow you to call it from Perl.

This method is deprecated, and will be removed from a future version of 
[FFI::TinyCC](https://metacpan.org/pod/FFI::TinyCC), but not before January 31, 2017.  It will issue a 
warning if you try to use it.  Instead of this:

    my $function = $ffi->get_ffi_raw($name, FFI::void);
    $function->();

Do this:

    use FFI::Raw;
    my $function = FFI::Raw->new_from_ptr($ffi->get_symbol($name), FFI::void);
    $function->();

Or better yet, use [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus) instead:

    use FFI::Platypus::Declare;
    attach [$ffi->get_symbol($name) => 'function'] => [] => 'void';
    function();

# EXAMPLES

## Calling Tiny C code from Perl

    use FFI::TinyCC;
    
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

    use FFI::TinyCC;
    use FFI::Platypus::Declare qw( opaque );
    
    my $say = closure { print $_[0], "\n" };
    my $ptr = cast '(string)->void' => opaque => $say;
    
    my $tcc = FFI::TinyCC->new;
    $tcc->add_symbol(say => $ptr);
    
    $tcc->compile_string(<<EOF);
    extern void say(const char *);
    
    int
    main(int argc, char *argv[])
    {
      int i;
      for(i=0; i<argc; i++)
      {
        say(argv[i]);
      }
    }
    EOF
    
    my $r = $tcc->run($0, @ARGV);
    
    exit $r;

## Attaching as a FFI::Platypus function from a Tiny C function

    use FFI::TinyCC;
    use FFI::Platypus::Declare qw( int );
    
    my $tcc = FFI::TinyCC->new;
    
    $tcc->compile_string(q{
      int
      calculate_square(int value)
      {
        return value*value;
      }
    });
    
    my $value = shift @ARGV;
    $value = 4 unless defined $value;
    
    my $address = $tcc->get_symbol('calculate_square');
    
    attach [$address => 'square'] => [int] => int;
    
    print square($value), "\n";

# CAVEATS

Tiny C is only supported on platforms with ARM or Intel processors.  All 
features may not be fully supported on all operating systems.

Tiny C is no longer supported by its original author, though various 
forks seem to have varying levels of support. We use the fork that comes 
with [Alien::TinyCC](https://metacpan.org/pod/Alien::TinyCC).

# SEE ALSO

- [FFI::TinyCC::Inline](https://metacpan.org/pod/FFI::TinyCC::Inline)
- [Tiny C](http://bellard.org/tcc/)
- [Tiny C Compiler Reference Documentation](http://bellard.org/tcc/tcc-doc.html)
- [FFI::Platypus](https://metacpan.org/pod/FFI::Platypus)
- [Alien::TinyCC](https://metacpan.org/pod/Alien::TinyCC)
- [C::TinyCompiler](https://metacpan.org/pod/C::TinyCompiler)

# BUNDLED SOFTWARE

This package also comes with a parser that was shamelessly stolen from 
[XS::TCC](https://metacpan.org/pod/XS::TCC), which I strongly suspect was itself shamelessly "borrowed" 
from [Inline::C::Parser::RegExp](https://metacpan.org/pod/Inline::C::Parser::RegExp)

The license details for the parser are:

Copyright 2002 Brian Ingerson
Copyright 2008, 2010-2012 Sisyphus
Copyright 2013 Steffen Muellero

This program is free software; you can redistribute it and/or modify it 
under the same terms as Perl itself.

# AUTHOR

Author: Graham Ollis <plicease@cpan.org>

Contributors:

aero

Dylan Cali (calid)

pipcet

# COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
