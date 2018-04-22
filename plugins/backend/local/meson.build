local_resources = gnome.compile_resources(
  'local_res',
  'local.gresource.xml'
)

subdir('libnxml')
subdir('libmrss')
subdir('rss-glib')


rss_glib_dir = join_paths(meson.current_source_dir(), 'rss-glib/')
rss_glib_vapi = vala_compiler.find_library('rss-glib-1.0', dirs: rss_glib_dir)
lib_rss_glib = declare_dependency(
  link_with: rss_glib_lib,
  include_directories: rss_glib_inc,
  dependencies: rss_glib_vapi
)

plugin_lib = shared_library(
  'local',
  [
    'localInterface.vala',
    'localUtils.vala',
    'Rfc822.vala',
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
