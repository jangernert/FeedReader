wallabag_resources = gnome.compile_resources(
  'wallabag_res',
  'wallabag.gresource.xml'
)

shared_library(
  'wallabag',
  [
    'WallabagAPI.vala',
    'WallabagSetup.vala'
  ],
  wallabag_resources,
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
    webkit2gtk,
    libxml,
    rest,
    json_glib
  ],
  link_with: [
    feedreader_lib
  ],
  install: true,
  install_dir: SHARE_PLUGINS_DIR,
  include_directories: include_directories('../../..')
)

install_data(
  [
    'org.gnome.feedreader.share.wallabag.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)

install_data(
  [
    'wallabag.plugin'
  ],
  install_dir: SHARE_PLUGINS_DIR
)
