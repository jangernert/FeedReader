feedly_resources = gnome.compile_resources(
  'feedly',
  'feedly.gresource.xml'
)

shared_library(
  'Feedly',
  [
    'feedlyAPI.vala',
    'feedlyInterface.vala',
    'feedlyUtils.vala',
    'feedlyConnection.vala'
  ],
  feedly_resources,
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
    'org.gnome.feedreader.feedly.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
