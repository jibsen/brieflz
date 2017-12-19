test_brieflz = executable('test_brieflz', 'test_brieflz.c',
  c_args : extra_flags,
  dependencies : brieflz_dep,
  install : get_option('install_tests'),
  install_dir : join_paths(get_option('libexecdir'), 'installed-tests/brieflz')
)

test('brieflz test', test_brieflz)
