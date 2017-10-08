project('FeedReader', ['vala', 'c'],
  version: '2.0.2',
  meson_version: '>= 0.41.0',
  license: 'GPL-3.0',
  default_options: ['prefix=/usr']
)

# Constants (paths)
VAPI_DIR              = join_paths(meson.current_source_dir(), 'vapi')
PO_DIR                = join_paths(meson.current_source_dir(), 'po')
SHARE_DIR			        = join_paths(get_option('prefix'),
                                    get_option('datadir'))
DATA_DIR              = join_paths(get_option('prefix'),
                                    get_option('datadir'),
                                    meson.project_name())
LOCALE_DIR            = join_paths(get_option('prefix'),
                                    get_option('localedir'))
PKGLIBDIR             = join_paths(get_option('prefix'),
                                    get_option('libdir'),
                                    meson.project_name())
SHARE_PLUGINS_DIR      = join_paths(PKGLIBDIR, 'pluginsShare')
BACKEND_PLUGINS_DIR    = join_paths(PKGLIBDIR, 'plugins')

# Define the vapi dir
add_project_arguments(
  ['--vapidir', VAPI_DIR],
  language: 'vala'
)

# Modules
gnome = import('gnome')
i18n = import('i18n')

# Compilers
vala_compiler = meson.get_compiler('vala')
c_compiler = meson.get_compiler('c')
# Dependencies
gdk_pixbuf          = dependency('gdk-pixbuf-2.0')
gee                 = dependency('gee-0.8')
glib                = dependency('glib-2.0')
goa                 = dependency('goa-1.0')
gstreamer           = dependency('gstreamer-1.0')
gstreamer_pbutils   = dependency('gstreamer-pbutils-1.0')
gtk                 = dependency('gtk+-3.0', version: '>=3.22')
json_glib           = dependency('json-glib-1.0')
libcurl             = c_compiler.find_library('libcurl')
libnotify           =  dependency('libnotify')
libpeas             = dependency('libpeas-1.0')
libsecret           = dependency('libsecret-1')
libsoup             = dependency('libsoup-2.4')
libxml              = dependency('libxml-2.0')
linux               = vala_compiler.find_library('linux')
posix               = vala_compiler.find_library('posix')
rest                = dependency('rest-0.7')
sqlite3             = dependency('sqlite3')
webkit2gtk          = dependency('webkit2gtk-4.0')

# Configuration
conf = configuration_data()
conf.set('GETTEXT_PACKAGE', meson.project_name())
conf.set('PREFIX', get_option('prefix'))
conf.set('VERSION', meson.project_version())
conf.set('PKGDATADIR', DATA_DIR)
conf.set('PKGLIBDIR', PKGLIBDIR)


configure_file(output: 'config.h', configuration: conf)
config_h_dir = include_directories('.')
c_args = [
  '-include', 'config.h'
]

# Build libraries
subdir('libraries/libgd')
subdir('libraries/libgtkimageview')
subdir('libraries/libIvy')
subdir('libraries/libVilistextum')
subdir('libraries/WebExtension')
subdir('data')


# VAPI's
libgd_vapi          = vala_compiler.find_library('gd-1.0', dirs: VAPI_DIR)
gtkimageview_vapi   = vala_compiler.find_library('gtkimageview', dirs: VAPI_DIR)
libvilistextum_vapi = vala_compiler.find_library('libvilistextum', dirs: VAPI_DIR)
libivy_vapi         = vala_compiler.find_library('ivy', required: false,
                                                  dirs: join_paths(meson.build_root(),
                                                                    'libraries/libIvy'))

libvilistextum  = declare_dependency(dependencies: libvilistextum_vapi)
libgd           = declare_dependency(dependencies: libgd_vapi)
libgtkimageview = declare_dependency(dependencies: gtkimageview_vapi)
libivy          = declare_dependency(dependencies: libivy_vapi)

vala_sources = [
  'src/FavIconCache.vala',
  'src/FeedReader.vala',
  'src/Widgets/AddPopover.vala',
  'src/Widgets/ArticleRow.vala',
  'src/Widgets/ArticleView.vala',
  'src/Widgets/ArticleViewHeader.vala',
  'src/Widgets/ArticleViewLoadProgress.vala',
  'src/Widgets/ArticleViewUrlOverlay.vala',
  'src/Widgets/BackendInfoPopover.vala',
  'src/Widgets/CategorieRow.vala',
  'src/Widgets/ColorCircle.vala',
  'src/Widgets/ColorPopover.vala',
  'src/Widgets/ColumnView.vala',
  'src/Widgets/ColumnViewHeader.vala',
  'src/Widgets/FeedList.vala',
  'src/Widgets/FeedListFooter.vala',
  'src/Widgets/FeedRow.vala',
  'src/Widgets/FullscreenButton.vala',
  'src/Widgets/FullscreenHeader.vala',
  'src/Widgets/HoverButton.vala',
  'src/Widgets/ImagePopup.vala',
  'src/Widgets/InAppNotification.vala',
  'src/Widgets/InfoBar.vala',
  'src/Widgets/LoginPage.vala',
  'src/Widgets/LoginRow.vala',
  'src/Widgets/MainWindow.vala',
  'src/Widgets/MediaPlayer.vala',
  'src/Widgets/MediaButton.vala',
  'src/Widgets/MediaRow.vala',
  'src/Widgets/ModeButton.vala',
  'src/Widgets/RemovePopover.vala',
  'src/Widgets/ResetPage.vala',
  'src/Widgets/ServiceSettingsPopover.vala',
  'src/Widgets/ShareRow.vala',
  'src/Widgets/ShortcutsWindow.vala',
  'src/Widgets/ServiceInfo.vala',
  'src/Widgets/Setting.vala',
  'src/Widgets/SettingsDialog.vala',
  'src/Widgets/SharePopover.vala',
  'src/Widgets/SimpleHeader.vala',
  'src/Widgets/SpringCleanPage.vala',
  'src/Widgets/TagRow.vala',
  'src/Widgets/TagPopover.vala',
  'src/Widgets/TagPopoverRow.vala',
  'src/Widgets/UpdateButton.vala',
  'src/Widgets/WebLoginPage.vala',
  'src/Widgets/ArticleList/ArticleList.vala',
  'src/Widgets/ArticleList/ArticleListBox.vala',
  'src/Widgets/ArticleList/ArticleListEmptyLabel.vala',
  'src/Widgets/ArticleList/ArticleListScroll.vala',
  'src/Share/share.vala',
  'src/Share/ServiceSetup.vala',
  'src/Share/ShareAccountInterface.vala',
  'src/Logger.vala',
  'src/Enums.vala',
  'src/FuncUtils.vala',
  'src/DataBaseReadOnly.vala',
  'src/ListUtils.vala',
  'src/Settings.vala',
  'src/StringUtils.vala',
  'src/Structs.vala',
  'src/Utils.vala',
  'src/QueryBuilder.vala',
  'src/ContentGrabber/grabberUtils.vala',
  'src/ContentGrabber/stringPair.vala',
  'src/Model/Feed.vala',
  'src/Model/Category.vala',
  'src/Model/Article.vala',
  'src/Model/Tag.vala',
  'src/Model/CachedAction.vala',
  'src/Model/InterfaceState.vala',
  'src/Model/ShareAccount.vala',
  'src/ActionCache.vala',
  'src/Backend/Backend.vala',
  'src/DataBaseWriteAccess.vala',
  'src/Notification.vala',
  'src/CachedActionManager.vala',
  'src/Backend/FeedServer.vala',
  'src/Backend/FeedServerInterface.vala',
  'src/Backend/OPMLparser.vala',
  'src/ContentGrabber/grabberConfig.vala',
  'src/ContentGrabber/grabber.vala',
  configure_file(
    input: 'Constants.vala.in',
    output: 'Constants.vala',
    configuration: conf
  )
]

executable(
  'feedreader',
  vala_sources,
  UI_RESOURCES,
  c_args: [
    '-DVERSION="' + meson.project_version() + '"',
    '-DGETTEXT_PACKAGE="'+ meson.project_name() +'"',
    '-DGNOMELOCALEDIR="' + LOCALE_DIR + '"'
  ],
  vala_args: [
    '--target-glib=2.38',
    '--pkg=posix',
    '--vapidir=' + VAPI_DIR,
    '--header=FeedReader.h',
    '--vapi=FeedReader.vapi',
    '--enable-experimental'
  ],
  install: true,
  dependencies: [
    glib,
    gtk,
    json_glib,
    libsoup,
    sqlite3,
    gee,
    libsecret,
    rest,
    webkit2gtk,
    gstreamer,
    gstreamer_pbutils,
    libpeas,
    libxml,
    goa,
    posix,
    goa,
    libgtkimageview,
    libgd,
    libvilistextum
  ]
)

# Build plugins and data files
subdir('plugins')
subdir('schemas')
subdir('po')
