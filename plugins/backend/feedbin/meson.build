feedbin_resources = gnome.compile_resources(
  'feedbin',
  'feedbin.gresource.xml'
)

shared_library(
  'Feedbin',
  [
    'feedbinAPI.vala',
    'feedbinInterface.vala',
    'feedbinUtils.vala',
    'feedbinConnection.vala'
  ],
  feedbin_resources,
  c_args: c_args,
  vala_args: vala_args,
  dependencies: [
    libpeas,
    gtk,
    gee,
    libsecret,
    sqlite3,
    libsoup,
    libxml,
    json_glib
  ],
  link_with: [
    feedreader_lib
  ],
  install: true,
  install_dir: BACKEND_PLUGINS_DIR
)

install_data(
  [
    'org.gnome.feedreader.feedbin.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
