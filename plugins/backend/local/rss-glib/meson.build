rss_glib_inc = include_directories(['.', '../libmrss'])
rss_glib_lib = static_library(
  'rss-glib',
  [
    'rss-document.c',
    'rss-marshal.c',
    'rss-item.c',
    'rss-parser.c'
  ],
  include_directories: rss_glib_inc,
  dependencies: glib,
  install: true,
  install_dir: [true, true, true]
)
