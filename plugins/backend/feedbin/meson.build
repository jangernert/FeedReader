feedbin_resources = gnome.compile_resources(
  'feedbin_res',
  'feedbin.gresource.xml'
)

plugin_lib = shared_library(
  'feedbin',
  [
    'feedbinAPI.vala',
    'feedbinInterface.vala',
    'feedbinUtils.vala'
  ],
  feedbin_resources,
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
    'org.gnome.feedreader.feedbin.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)

install_data(
  [
    'feedbin.plugin'
  ],
  install_dir: BACKEND_PLUGINS_DIR
)

plugin_test = executable(
  'test_feedbin',
  [
    'TestFeedbin.vala'
  ],
  c_args: c_args,
  # The tests intentionally don't catch exceptions
  vala_args: vala_args + ['--disable-warnings'],
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
    feedreader_lib,
    plugin_lib
  ],
  include_directories: include_directories('../../..')
)

# FIXME: Why do we get errors like `g_object_new_with_properties: assertion 'G_TYPE_IS_OBJECT (object_type)' failed`
# with the new meson build?
#test('Feedbin plugin', plugin_test)
