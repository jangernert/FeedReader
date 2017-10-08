message('TODO: Compiling resources')
UI_RESOURCES = gnome.compile_resources(
  'FeedReader',
  'org.gnome.FeedReader.gresource.xml'
)

message('TODO: Making a .desktop file')
i18n.merge_file(
  input: 'org.gnome.FeedReader.desktop.in',
  output: 'org.gnome.FeedReader.desktop',
  po_dir: PO_DIR,
  type: 'desktop',
  install: true,
  install_dir: join_paths(SHARE_DIR, 'applications')
)

i18n.merge_file(
  input: 'org.gnome.FeedReader-autostart.desktop.in',
  output: 'org.gnome.FeedReader-autostart.desktop',
  po_dir: PO_DIR,
  type: 'desktop',
  install: true,
  install_dir: DATA_DIR
)

message('TODO: Preparing appdata')
i18n.merge_file(
  input: 'org.gnome.FeedReader.appdata.xml.in',
  output: 'org.gnome.FeedReader.appdata.xml',
  po_dir: PO_DIR,
  install: true,
  install_dir: join_paths(SHARE_DIR, 'appdata')
)

subdir('application-icons')
