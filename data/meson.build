UI_RESOURCES = gnome.compile_resources(
  'feedreader_res',
  'org.gnome.FeedReader.gresource.xml',
)

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

i18n.merge_file(
  input: 'org.gnome.FeedReader.appdata.xml.in',
  output: 'org.gnome.FeedReader.appdata.xml',
  po_dir: PO_DIR,
  install: true,
  install_dir: join_paths(SHARE_DIR, 'appdata')
)

subdir('application-icons')

install_subdir('GrabberConfig', install_dir : DATA_DIR)
