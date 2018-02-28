browser_resources = gnome.compile_resources(
  'browser_res',
  'browser.gresource.xml'
)

shared_library(
  'browser',
  [
    'Browser.vala'
  ],
  browser_resources,
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
    libxml
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
    'browser.plugin'
  ],
  install_dir: SHARE_PLUGINS_DIR
)
