browser_resources = gnome.compile_resources(
  'browser',
  'browser.gresource.xml'
)

shared_library(
  'Browser',
  [
    'Browser.vala'
  ],
  browser_resources,
  c_args: c_args,
  vala_args: vala_args,
  dependencies: [
    libpeas,
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
  install_dir: SHARE_PLUGINS_DIR
)
