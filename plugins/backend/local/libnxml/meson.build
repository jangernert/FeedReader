nxml_inc = include_directories('.')
nxml_lib = static_library(
  'nxml',
  [
    'nxml_download.c',
    'nxml_easy.c',
    'nxml_edit.c',
    'nxml_error.c',
    'nxml_free.c',
    'nxml_init.c',
    'nxml_namespace.c',
    'nxml_parser.c',
    'nxml_string.c',
    'nxml_tools.c',
    'nxml_utf.c',
    'nxml_write.c'
  ],
  include_directories: nxml_inc,
  install: true,
  install_dir: [true, true, true]
)
