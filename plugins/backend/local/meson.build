local_resources = gnome.compile_resources(
  'local',
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


shared_library(
  'Local',
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
    gtk,
    gee,
    libsecret,
    sqlite3,
    libsoup,
    libxml,
    json_glib,
    libcurl,
    lib_rss_glib
  ],
  link_with: [
    feedreader_lib,
    mrss_lib,
    nxml_lib
  ],
  install: true,
  install_dir: BACKEND_PLUGINS_DIR
)
