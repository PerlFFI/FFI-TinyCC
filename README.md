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

## add\_file

    $tcc->add_file('foo.c');
    $tcc->add_file('foo.o');
    $tcc->add_file('foo.so'); # or dll on windows

Add a file, DLL, shared object or object file.

## compile\_string

    $tcc->compile_string($c_code);

Compile a string containing C source code.

## run

    my $exit_value = $tcc->run(@arguments);

## get\_symbol

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
