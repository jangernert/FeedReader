telegram_resources = gnome.compile_resources(
  'telegram',
  'telegram.gresource.xml'
)

shared_library(
  'Telegram',
  [
    'Telegram.vala',
    'TelegramForm.vala',
    'TelegramSetup.vala'
  ],
  telegram_resources,
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

install_data(
  [
    'org.gnome.feedreader.share.telegram.gschema.xml'
  ],
  install_dir: join_paths(SHARE_DIR, 'glib-2.0/schemas')
)
