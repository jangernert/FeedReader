owncloud_resources = gnome.compile_resources(
  'owncloud',
  'owncloud.gresource.xml'
)

shared_library(
  'Owncloud',
  [
    'OwncloudNewsAPI.vala',
    'OwncloudNewsInterface.vala',
    'OwncloudNewsUtils.vala',
    'OwncloudNewsMessage.vala'
  ],
  owncloud_resources,
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
    'org.gnome.feedreader.owncloud.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
