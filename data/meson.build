UI_RESOURCES = gnome.compile_resources(
  'feedreader_res',
  'org.gnome.FeedReader.gresource.xml',
)

desktop_file = i18n.merge_file(
  input: 'org.gnome.FeedReader.desktop.in',
  output: 'org.gnome.FeedReader.desktop',
  po_dir: PO_DIR,
  type: 'desktop',
  install: true,
  install_dir: join_paths(SHARE_DIR, 'applications')
)

desktop_autostart_file = i18n.merge_file(
  input: 'org.gnome.FeedReader-autostart.desktop.in',
  output: 'org.gnome.FeedReader-autostart.desktop',
  po_dir: PO_DIR,
  type: 'desktop',
  install: true,
  install_dir: DATA_DIR
)

appdata_file = i18n.merge_file(
  input: 'org.gnome.FeedReader.appdata.xml.in',
  output: 'org.gnome.FeedReader.appdata.xml',
  po_dir: PO_DIR,
  install: true,
  install_dir: join_paths(SHARE_DIR, 'metainfo')
)


desktop_file_validate = find_program('desktop-file-validate', required:false)

if desktop_file_validate.found()
	foreach file: [desktop_file, desktop_autostart_file]
		test (
			'Validate desktop file',
			desktop_file_validate,
			args: file.full_path()
		)
	endforeach
endif

appstreamcli = find_program('appstream-util', required:false)

if appstreamcli.found()
  test (
    'Validate appdata file',
    appstreamcli,
    args: ['validate-relax', '--nonet', appdata_file.full_path()]
  )
endif


subdir('application-icons')

install_subdir('GrabberConfig', install_dir: DATA_DIR)
