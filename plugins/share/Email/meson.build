mail_resources = gnome.compile_resources(
  'mail',
  'mail.gresource.xml'
)

shared_library(
  'Email',
  [
    'Email.vala',
    'EmailForm.vala'
  ],
  mail_resources,
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
    libxml,
    feedreader
  ],
  install: true,
  install_dir: SHARE_PLUGINS_DIR
)
