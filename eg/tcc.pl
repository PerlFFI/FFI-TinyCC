use strict;
use warnings;
use v5.10;
use FFI::Raw;

use constant {
  _lib => 'lib/libtcc.so',
  
  # tcc_set_output_type
  TCC_OUTPUT_MEMORY     => 0,
  TCC_OUTPUT_EXE        => 1,
  TCC_OUTPUT_DLL        => 2,
  TCC_OUTPUT_OBJ        => 3,
  TCC_OUTPUT_PREPROCESS => 4,
  
  # ??
  TCC_OUTPUT_FORMAT_ELF    => 0,
  TCC_OUTPUT_FORMAT_BINARY => 1,
  TCC_OUTPUT_FORMAT_COFF   => 2,
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

my $tcc = _new->call;

my $prog = <<EOF;
int
main(int argc, char *argv[])
{
  printf("hi there\n");
}
EOF

_compile_string->call($tcc, $prog);
_run->call($tcc, 0, undef);

_delete->call($tcc);

