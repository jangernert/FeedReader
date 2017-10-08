gd_inc = include_directories('.')
gd_lib = static_library(
  'gd',
  [
    'gd-notification.c',
    'gd-types-catalog.c'
  ],
  dependencies: [
    glib,
    gtk
  ],
  install: true,
  install_dir: [true, true, true]
)
