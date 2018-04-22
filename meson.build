project('feedreader', ['vala', 'c'],
  version: '2.2-dev',
  meson_version: '>= 0.44.1',
  license: 'GPL-3.0',
  default_options: ['prefix=/usr']
)

# Constants (paths)
VAPI_DIR               = join_paths(meson.current_source_dir(), 'vapi')
PO_DIR                 = join_paths(meson.current_source_dir(), 'po')
SHARE_DIR              = join_paths(get_option('prefix'),
                                    get_option('datadir'))
DATA_DIR               = join_paths(get_option('prefix'),
                                    get_option('datadir'),
                                    meson.project_name())
LOCALE_DIR             = join_paths(get_option('prefix'),
                                    get_option('localedir'))
PKGLIBDIR              = join_paths(get_option('prefix'),
                                    get_option('libdir'),
                                    meson.project_name())
SHARE_PLUGINS_DIR      = join_paths(PKGLIBDIR, 'pluginsShare')
BACKEND_PLUGINS_DIR    = join_paths(PKGLIBDIR, 'plugins')

# Define the vapi dir
add_project_arguments(['--vapidir=' + VAPI_DIR], language: 'vala')

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
libnotify           = dependency('libnotify')
libpeas             = dependency('libpeas-1.0')
libsecret           = dependency('libsecret-1')
libsoup             = dependency('libsoup-2.4')
libxml              = dependency('libxml-2.0')
linux               = vala_compiler.find_library('linux')
posix               = vala_compiler.find_library('posix')
rest                = dependency('rest-0.7')
sqlite3             = dependency('sqlite3')
webkit2gtk          = dependency('webkit2gtk-4.0')
webkitextension     = dependency('webkit2gtk-web-extension-4.0')
libunity            = dependency('unity', required: false)

# Configuration
conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set('PREFIX', get_option('prefix'))
conf.set('VERSION', meson.project_version())
conf.set('LOCALE_DIR', LOCALE_DIR)
conf.set('PKGDATADIR', DATA_DIR)
conf.set('PKGLIBDIR', PKGLIBDIR)

intermediate = configure_file(
	input: 'Constants.vala.in',
	output: 'Constants.intermediate.vala',
	configuration: conf)

constants = vcs_tag(
	input : intermediate,
	output : 'Constants.vala',
	command : ['git', 'show-ref', '-s', 'refs/heads/master'],
	replace_string: '#GIT_SHA1#')



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

# libVilistextum
libvilistextum  = declare_dependency(
  link_with: vilistextum_lib,
  include_directories: vilistextum_inc,
  dependencies: libvilistextum_vapi
)

# libgd
libgd = declare_dependency(
  link_with: gd_lib,
  include_directories: gd_inc,
  dependencies: [libgd_vapi]
)

# GtkImageView
libgtkimageview = declare_dependency(
  link_with: gtkimageview_lib,
  include_directories: gtkimageview_inc,
  dependencies: [
    gtkimageview_vapi,
    c_compiler.find_library('m', required: false)
  ]
)

# libIvy
libivy = declare_dependency(
  link_with: ivy_lib,
  include_directories: ivy_inc
)

vala_sources = [
  constants,
  'src/FavIcon.vala',
  'src/FeedReader.vala',
  'src/Password.vala',
  'src/SQLite.vala',
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
  'src/ContentGrabber/grabber.vala'
]


c_args = [
  '-g',
  '-w',
  '-rdynamic',
  '-DVERSION="' + meson.project_version() + '"',
  '-DGETTEXT_PACKAGE="'+ meson.project_name() +'"',
  '-DGNOMELOCALEDIR="' + LOCALE_DIR + '"',
  '-DGOA_API_IS_SUBJECT_TO_CHANGE'
]

vala_args = [
  '--enable-experimental',
  '--target-glib','2.50'
]

feedreader_deps = [
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
    libivy,
    libgtkimageview,
    libvilistextum,
    libgd
  ]


if libunity.found()
	message('libUnity support ON')
	feedreader_deps  += [ libunity ]
	vala_args += ['-D', 'LIBUNITY']
else
	message('libUnity support OFF')
endif

# Creating an executable file
feedreader_lib = static_library(
  'FeedReader',
  vala_sources,
  c_args: c_args,
  vala_args: vala_args,
  vala_header: 'FeedReader.h',
  vala_vapi: 'FeedReader.vapi',
  dependencies: feedreader_deps,
  install: true
)

c_args = c_args + ['-include','FeedReader.h',]

# Build plugins and data files
subdir('plugins')
subdir('schemas')
subdir('po')

# Create an executable file
executable(
  'feedreader',
  UI_RESOURCES,
  link_with: [
    feedreader_lib
  ],
  dependencies: [
    gtkimageview_vapi,
    libvilistextum_vapi,
    webkit2gtk
  ],
  install: true
)

# Post install script
meson.add_install_script('meson_post_install.py')
