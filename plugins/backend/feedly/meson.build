feedly_resources = gnome.compile_resources(
  'feedly_res',
  'feedly.gresource.xml'
)

shared_library(
  'feedly',
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
    libgd,
    gtk,
    gee,
    libsecret,
    sqlite3,
    libsoup,
    libxml,
    json_glib,
    webkit2gtk
  ],
  link_with: [
    feedreader_lib
  ],
  install: true,
  install_dir: BACKEND_PLUGINS_DIR,
  include_directories: include_directories('../../..')
)

install_data(
  [
    'org.gnome.feedreader.feedly.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)

install_data(
  [
    'feedly.plugin'
  ],
  install_dir: BACKEND_PLUGINS_DIR
)
