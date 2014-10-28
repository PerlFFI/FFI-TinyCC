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

# CONSTRUCTOR

## new

    my $tcc = FFI::TinyCC->new;

Create a new TinyCC instance.

# METHODS

Methods will generally throw an exception on failure.

## Compile

### set\_options

    $tcc->set_options($options);

Set compile options, as you would on the command line, for example:

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
To call Perl from your C code, you can use [FFI::Raw::Callback](https://metacpan.org/pod/FFI::Raw::Callback),
like so:

    use FFI::Raw;
    use FFI::TinyCC;
    
    my $tcc = FFI::TinyCC->new;
    # note that you want to make sure you keep
    # the reference $callback around as a my
    # or our var because you don't want the
    # callback deallocated before it gets called
    my $callback = FFI::Raw::Callback->new(
      sub { "$_[0] x $_[1] " },
      FFI::Raw::str,
      FFI::Raw::int, FFI::Raw::int,
    );
    
    $tcc->add_symbol(dim => $callback);
    
    $tcc->compile_string(q{
      extern const char *dim(int arg);
      int
      main(int argc, char *argv[])
      {
        puts(arg(2,4));
      }
    });
    
    $tcc->run; # prints "2 x 4"

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
Example:

    my $tcc = FFI::Raw->new;
    
    $tcc->compile_string(q{
      int calculate_square(int value) {
        return value*value;
      }
    });
    
    my $square = $tcc->get_ffi_raw('calculate_square');
    say $square->call(4); # prints 16

### output\_file

    $tcc->output_file($filename);

Output the generated code (either executable, object or DLL) to the given filename.
The type of output is specified by the [set\_output\_type](https://metacpan.org/pod/FFI::TinyCC#set_output_type)
method.

# SEE ALSO

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
