oldreader_resources = gnome.compile_resources(
  'oldreader',
  'oldreader.gresource.xml'
)

shared_library(
  'Oldreader',
  [
    'oldreaderAPI.vala',
    'oldreaderInterface.vala',
    'oldreaderUtils.vala',
    'oldreaderConnection.vala'
  ],
  oldreader_resources,
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
    'org.gnome.feedreader.oldreader.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
