# FFI::TinyCC

Tiny C Compiler for FFI

# SYNOPSIS

# DESCRIPTION

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

### compile\_string

    $tcc->compile_string($c_code);

Compile a string containing C source code.

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

### run

    my $exit_value = $tcc->run(@arguments);

### get\_symbol

    my $pointer = $tcc->get_symbol($symbol_name);

Return symbol value or undef if not found.  This can be passed into
[FFI::Raw](https://metacpan.org/pod/FFI::Raw) or similar for use in your script.

# SEE ALSO

- [FFI::Raw](https://metacpan.org/pod/FFI::Raw)
- [Alien::TinyCC](https://metacpan.org/pod/Alien::TinyCC)

# AUTHOR

Graham Ollis <plicease@cpan.org>

# COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Graham Ollis.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
