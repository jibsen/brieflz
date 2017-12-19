blzpack_flags = extra_flags
if cc_id == 'msvc'
  blzpack_flags += '/D_CRT_SECURE_NO_WARNINGS'
endif

executable('blzpack', 'blzpack.c', 'parg.c',
  c_args : blzpack_flags,
  dependencies : brieflz_dep,
  install : build_install
)
