project('brieflz', 'c',
  meson_version : '>=0.43.0',
  default_options : [
    'buildtype=debugoptimized',
    'default_library=static',
    'warning_level=3',
  ],
  version : '1.1.0',
  license : 'Zlib'
)

cc = meson.get_compiler('c')
cc_id = cc.get_id()

# Use default_library, but allow overriding it
lib_type = get_option('lib_type')
if lib_type == 'default'
  lib_type = get_option('default_library')
endif

# Provide install unless built as static library subproject
if get_option('build_install') == 'default'
  build_install = lib_type == 'shared' or not meson.is_subproject()
else
  build_install = get_option('build_install') == 'true'
endif

# Compiler flags
if cc_id == 'clang'
  test_flags = ['-Weverything', '-pedantic']
elif cc_id == 'gcc'
  test_flags = [
    '-Wall',
    '-Wextra',
    '-pedantic',
    '-Wshadow',
    '-Wpointer-arith',
    '-Wcast-qual',
    '-Wcast-align',
    '-Wstrict-prototypes',
    '-Wmissing-prototypes',
  ]
elif cc_id == 'msvc'
  test_flags = ['/analyze']
else
  test_flags = []
endif

extra_flags = cc.get_supported_arguments(test_flags)

if lib_type == 'shared'
  build_flags = ['-DBLZ_DLL', '-DBLZ_DLL_EXPORTS']
  if cc_id != 'msvc' and cc.has_argument('-fvisibility=hidden')
    build_flags += '-fvisibility=hidden'
  endif
  use_flags = ['-DBLZ_DLL']
else
  build_flags = []
  use_flags = []
endif

src = [
  'brieflz.c',
  'depack.c',
  'depacks.c',
]

if lib_type == 'shared'
  lib = shared_library('brieflz', src,
    c_args : build_flags + extra_flags,
    version : meson.project_version(),
    install : build_install
  )
else
  lib = static_library('brieflz', src,
    c_args : build_flags + extra_flags,
    install : build_install
  )
endif

if build_install
  install_headers('brieflz.h')
endif

# Declare dependency object
brieflz_dep = declare_dependency(
  compile_args : use_flags,
  include_directories : include_directories('.'),
  link_with : lib,
  version : meson.project_version()
)

subdir('example')

if get_option('build_tests')
  subdir('test')
endif

pkg_mod = import('pkgconfig')
pkg_mod.generate(
  extra_cflags : use_flags,
  libraries : lib,
  filebase : 'brieflz',
  name : 'BriefLZ',
  description : 'Small fast Lempel-Ziv compression library',
  version : meson.project_version(),
  url : 'https://github.com/jibsen/brieflz/'
)
