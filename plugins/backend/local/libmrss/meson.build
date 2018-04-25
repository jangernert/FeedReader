mrss_inc = include_directories(['.', '../libnxml'])
mrss_lib = static_library(
  'mrss',
  [
    'mrss_download.c',
    'mrss_edit.c',
    'mrss_free.c',
    'mrss_generic.c',
    'mrss_options.c',
    'mrss_parser.c',
    'mrss_search.c',
    'mrss_write.c'
  ],
  c_args: ['-Wno-comment', '-Wno-pointer-to-int-cast'],
  include_directories: mrss_inc
)
