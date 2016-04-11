project (FeedReader)
cmake_minimum_required (VERSION 2.6)
include_directories(${CMAKE_SOURCE_DIR}/libVilistextum)
include_directories(${CMAKE_SOURCE_DIR}/staticLibs)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
option(WITH_DEBUG "Compile daemon binary with debugging symbols" OFF)
option(WITH_LIBUNITY "Adds a Badge with the count of the unread articles to the dockitem" ON)
option(USE_WEBKIT_4 "Compile with Webkit2Gtk 4.0 instead of 3.0" OFF)


set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME "feedreader")
set (DAEMON_NAME ${EXEC_NAME}-daemon)
set (DEBUG_NAME ${EXEC_NAME}-debug)
set (RELEASE_NAME "RSS Client")
set (VERSION "1.2.1")
set (VERSION_INFO "whats up world")

find_package(PkgConfig)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
add_subdirectory (schemas)
add_subdirectory (libVilistextum)

include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/GitSHA1.vala.in" "${CMAKE_SOURCE_DIR}/GitSHA1.vala" @ONLY)


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

set(UI_OPTIONS
    --target-glib=2.32)

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

include(ValaPrecompile)
vala_precompile(UI ${EXEC_NAME}
    GitSHA1.vala
    src/DBusConnection.vala
    src/FeedReader.vala
    src/Logger.vala
    src/Backends/ttrss/TTRSS_Utils.vala
    src/Backends/owncloud/OwncloudNews_Utils.vala
    src/Backends/inoreader/InoReader_Utils.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/InterfaceState.vala
    src/Model/ShareAccount.vala
    src/Constants.vala
    src/dbUI.vala
    src/UiUtils.vala
    src/Utils.vala
    src/QueryBuilder.vala
    src/Widgets/AddPopover.vala
    src/Widgets/ArticleList.vala
    src/Widgets/ArticleListOverlay.vala
    src/Widgets/ArticleRow.vala
    src/Widgets/ArticleView.vala
    src/Widgets/CategorieRow.vala
    src/Widgets/ColorCircle.vala
    src/Widgets/ColorPopover.vala
    src/Widgets/ContentPage.vala
    src/Widgets/FeedList.vala
    src/Widgets/FeedListFooter.vala
    src/Widgets/FeedRow.vala
    src/Widgets/HoverButton.vala
    src/Widgets/ImagePopup.vala
    src/Widgets/InAppNotification.vala
    src/Widgets/LoginPage.vala
    src/Widgets/MainWindow.vala
    src/Widgets/ModeButton.vala
    src/Widgets/ReaderHeaderbar.vala
    src/Widgets/RemovePopover.vala
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

CUSTOM_VAPIS
    vapi/libvilistextum.vapi
    vapi/gtkimageview.vapi
    vapi/gd-1.0.vapi
)

add_executable(${EXEC_NAME} ${UI})
target_link_libraries(${EXEC_NAME} vilistextum)
target_link_libraries(${EXEC_NAME} ${CMAKE_SOURCE_DIR}/staticLibs/libgtkimageview.a)
target_link_libraries(${EXEC_NAME} ${CMAKE_SOURCE_DIR}/staticLibs/libgd.a)


set(DAEMON_OPTIONS
    --target-glib=2.32)
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

if(WITH_DEBUG)
	list(APPEND DAEMON_OPTIONS -g)
endif(WITH_DEBUG)

vala_precompile(daemon ${DAEMON_NAME}
    src/Constants.vala
    src/Daemon.vala
    src/dbUI.vala
    src/dbDaemon.vala
    src/Logger.vala
    src/Utils.vala
    src/OfflineActionManager.vala
    src/QueryBuilder.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/OfflineAction.vala
    src/Model/InterfaceState.vala
    src/Backends/FeedServer.vala
    src/Backends/ttrss/TTRSS_API.vala
    src/Backends/ttrss/TTRSS_Utils.vala
    src/Backends/ttrss/TTRSS_Message.vala
    src/Backends/feedly/FeedlyAPI.vala
    src/Backends/feedly/FeedlyConnection.vala
    src/Backends/inoreader/InoReaderAPI.vala
    src/Backends/inoreader/InoReaderConnection.vala
    src/Backends/inoreader/InoReader_Utils.vala
    src/Backends/owncloud/OwncloudNewsAPI.vala
    src/Backends/owncloud/OwncloudNews_Message.vala
    src/Backends/owncloud/OwncloudNews_Utils.vala
    src/ContentGrabber/stringPair.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
    src/ContentGrabber/ReadabilityParserAPI.vala
    src/Debug/DebugUtils.vala


PACKAGES
    ${DAEMON_PACKAGES}

OPTIONS
    ${DAEMON_OPTIONS}

CUSTOM_VAPIS
    vapi/libvilistextum.vapi
)

add_executable(${DAEMON_NAME} ${daemon})
target_link_libraries(${DAEMON_NAME} vilistextum)


set(DEBUG_OPTIONS
    --target-glib=2.32)
set(DEBUG_PACKAGES
    glib-2.0>=2.32
    gtk+-3.0
    gio-2.0
    sqlite3
    gee-0.8
    libsoup-2.4
    json-glib-1.0
    libxml-2.0)

vala_precompile(debug ${DEBUG_NAME}
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
    src/Model/OfflineAction.vala
    src/Constants.vala
    src/ContentGrabber/stringPair.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
    src/ContentGrabber/ReadabilityParserAPI.vala
    src/Debug/DebugServer.vala
    src/Debug/DebugUtils.vala


PACKAGES
    ${DEBUG_PACKAGES}

OPTIONS
    ${DEBUG_OPTIONS}

CUSTOM_VAPIS
    vapi/libvilistextum.vapi
)

add_executable(${DEBUG_NAME} ${debug})
target_link_libraries(${DEBUG_NAME} vilistextum)
#target_compile_definitions(${DEBUG_NAME} PRIVATE DAEMONCODE=1)

# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake)

install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${DAEMON_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${DEBUG_NAME} RUNTIME DESTINATION bin)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service DESTINATION ${DATADIR}/dbus-1/services/)
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor DESTINATION /usr/share/icons)
install (CODE "execute_process (COMMAND gtk-update-icon-cache /usr/share/icons/hicolor)")
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/FeedReader.css DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/ArticleView DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/GrabberConfig DESTINATION ${PKGDATADIR})
