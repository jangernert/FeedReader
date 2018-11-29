local_resources = gnome.compile_resources(
  'local_res',
  'local.gresource.xml'
)

plugin_lib = shared_library(
  'local',
  [
    'localInterface.vala',
    'localUtils.vala',
    'SuggestedFeedRow.vala'
  ],
  local_resources,
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
    libcurl,
    lib_rss_glib,
    webkit2gtk
  ],
  link_with: [
    feedreader_lib,
    mrss_lib,
    nxml_lib
  ],
  install: true,
  install_dir: BACKEND_PLUGINS_DIR,
  include_directories: include_directories('../../..')
)

install_data(
  [
    'local.plugin'
  ],
  install_dir: BACKEND_PLUGINS_DIR
)

plugin_test = executable(
  'test_local',
  [
    'TestLocalRSS.vala'
  ],
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
    libcurl,
    lib_rss_glib,
    webkit2gtk
  ],
  link_with: [
    plugin_lib,
    feedreader_lib,
    mrss_lib,
    nxml_lib
  ],
  include_directories: include_directories('../../..')
)

if gtester.found()
	test('Local plugin', gtester, args:['-k', '-o', meson.build_root() + '/local.gtester.log', plugin_test])
else
	test('Local plugin', plugin_test)
endif
