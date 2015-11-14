project (RSSReader)
cmake_minimum_required (VERSION 2.6)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
option(WITH_DEBUG "Compile daemon binary with debugging symbols" OFF)
option(WITH_LIBUNITY "Adds a Badge with the count of the unread articles to the dockitem" ON)
option(USE_WEBKIT_4 "Compile with Webkit2Gtk 4.0 instead of 3.0" OFF)
option(WITH_VILISTEXTUM "Use vilistextum as a fallback when html2text fails to create a preview" ON)


set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME "feedreader")
set (DAEMON_NAME ${EXEC_NAME}-daemon)
set (RELEASE_NAME "RSS Client")
set (VERSION "1.2.1")
set (VERSION_INFO "whats up world")

find_package(PkgConfig)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
add_subdirectory (schemas)


set(MODULES gtk+-3.0 json-glib-1.0 gee-0.8 libsoup-2.4 sqlite3 libsecret-1 libnotify libxml-2.0 rest-0.7)

if(WITH_LIBUNITY)
	list(APPEND MODULES unity)
endif(WITH_LIBUNITY)

if(USE_WEBKIT_4)
	list(APPEND MODULES webkit2gtk-4.0)
else(USE_WEBKIT_4)
	list(APPEND MODULES webkit2gtk-3.0)
endif(USE_WEBKIT_4)

pkg_check_modules(DEPS REQUIRED ${MODULES})

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES} -lm)
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.24" MINIMUM)

set(UI_OPTIONS --target-glib=2.32)
set(UI_PACKAGES
	glib-2.0>=2.32
    gtk+-3.0
    json-glib-1.0
    libsoup-2.4
    sqlite3
    gee-0.8
    libsecret-1
    libnotify
    rest-0.7)

if(USE_WEBKIT_4)
	list(APPEND UI_PACKAGES WebKit2-4.0)
	list(APPEND UI_OPTIONS --define USE_WEBKIT_4)
else(USE_WEBKIT_4)
	list(APPEND UI_PACKAGES WebKit2-3.0)
endif(USE_WEBKIT_4)

if(WITH_VILISTEXTUM)
	list(APPEND UI_OPTIONS --define WITH_VILISTEXTUM)
endif(WITH_VILISTEXTUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(UI ${EXEC_NAME}
    src/FeedReader.vala
    src/Logger.vala
    src/Backends/ttrss/TTRSS_Utils.vala
    src/Backends/owncloud/OwncloudNews_Utils.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/InterfaceState.vala
    src/Model/ShareAccount.vala
    src/Constants.vala
    src/dbUI.vala
    src/Utils.vala
    src/QueryBuilder.vala
    src/Widgets/ArticleList.vala
    src/Widgets/ArticleListOverlay.vala
    src/Widgets/ArticleRow.vala
    src/Widgets/ArticleView.vala
    src/Widgets/CategorieRow.vala
    src/Widgets/ColorCircle.vala
    src/Widgets/ColorPopover.vala
    src/Widgets/ContentPage.vala
    src/Widgets/FeedList.vala
    src/Widgets/FeedRow.vala
    src/Widgets/HoverButton.vala
    src/Widgets/LoginPage.vala
    src/Widgets/MainWindow.vala
    src/Widgets/ModeButton.vala
    src/Widgets/ReaderHeaderbar.vala
    src/Widgets/ResetPage.vala
    src/Widgets/ServiceSettingsPopover.vala
    src/Widgets/ServiceSettingsRow.vala
    src/Widgets/ShareRow.vala
    src/Widgets/ServiceInfo.vala
    src/Widgets/Setting.vala
    src/Widgets/SettingsDialog.vala
    src/Widgets/SharePopover.vala
    src/Widgets/SpringCleanPage.vala
    src/Widgets/TagRow.vala
    src/Widgets/TagPopover.vala
    src/Widgets/TagPopoverRow.vala
    src/Widgets/UpdateButton.vala
    src/Widgets/WebLoginPage.vala
    src/ContentGrabber/stringPair.vala
    src/Backends/ttrss/TTRSS_Message.vala
    src/Share/ReadabilityAPI.vala
    src/Share/PocketAPI.vala
    src/Share/InstapaperAPI.vala
    src/Share/share.vala

# tell what libraries to use when compiling
PACKAGES
    ${UI_PACKAGES}

OPTIONS
    ${UI_OPTIONS}

)


set(DAEMON_OPTIONS
    --target-glib=2.32
    --define DAEMONCODE)
set(DAEMON_PACKAGES
    glib-2.0>=2.32
    gio-2.0
    sqlite3
    gee-0.8
    libsoup-2.4
    json-glib-1.0
    libnotify
    libsecret-1
    libxml-2.0
    rest-0.7)

if(WITH_LIBUNITY)
	list(APPEND DAEMON_OPTIONS --define WITH_LIBUNITY)
	list(APPEND DAEMON_PACKAGES unity)
endif(WITH_LIBUNITY)

if(WITH_VILISTEXTUM)
	list(APPEND DAEMON_OPTIONS --define WITH_VILISTEXTUM)
endif(WITH_VILISTEXTUM)

if(WITH_DEBUG)
	list(APPEND DAEMON_OPTIONS -g)
endif(WITH_DEBUG)

vala_precompile(daemon ${DAEMON_NAME}
    src/Daemon.vala
    src/dbUI.vala
    src/dbDaemon.vala
    src/Logger.vala
    src/Utils.vala
    src/QueryBuilder.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/InterfaceState.vala
    src/Constants.vala
    src/Backends/FeedServer.vala
    src/Backends/ttrss/TTRSS_API.vala
    src/Backends/ttrss/TTRSS_Utils.vala
    src/Backends/ttrss/TTRSS_Message.vala
    src/Backends/feedly/FeedlyAPI.vala
    src/Backends/feedly/FeedlyConnection.vala
    src/Backends/owncloud/OwncloudNewsAPI.vala
    src/Backends/owncloud/OwncloudNews_Message.vala
    src/Backends/owncloud/OwncloudNews_Utils.vala
    src/ContentGrabber/stringPair.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
    src/ContentGrabber/ReadabilityParserAPI.vala


PACKAGES
    ${DAEMON_PACKAGES}

OPTIONS
    ${DAEMON_OPTIONS}
)

# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake)



# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${UI})
add_executable(${DAEMON_NAME} ${daemon})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${DAEMON_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service DESTINATION ${DATADIR}/dbus-1/services/)
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor DESTINATION /usr/share/icons)
install (CODE "execute_process (COMMAND gtk-update-icon-cache /usr/share/icons/hicolor)")
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/FeedReader.css DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/ArticleView DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/GrabberConfig DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/html2textrc DESTINATION ${PKGDATADIR})
