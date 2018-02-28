ttrss_resources = gnome.compile_resources(
  'ttrss',
  'ttrss.gresource.xml'
)

shared_library(
  'Ttrss',
  [
    'ttrssAPI.vala',
    'ttrssInterface.vala',
    'ttrssUtils.vala',
    'ttrssMessage.vala'
  ],
  ttrss_resources,
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
    'org.gnome.feedreader.ttrss.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
