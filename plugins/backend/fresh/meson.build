fresh_resources = gnome.compile_resources(
  'fresh',
  'fresh.gresource.xml'
)

shared_library(
  'Fresh',
  [
    'freshAPI.vala',
    'freshInterface.vala',
    'freshUtils.vala',
    'freshConnection.vala'
  ],
  fresh_resources,
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
    json_glib,
    feedreader
  ],
  install: true,
  install_dir: BACKEND_PLUGINS_DIR
)

install_data(
  [
    'org.gnome.feedreader.fresh.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
