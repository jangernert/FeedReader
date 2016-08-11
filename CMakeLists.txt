project (FeedReader)
cmake_minimum_required (VERSION 2.6)
include_directories(${CMAKE_SOURCE_DIR}/libVilistextum)
include_directories(${CMAKE_SOURCE_DIR}/libgtkimageview)
include_directories(${CMAKE_SOURCE_DIR})


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
option(WITH_DEBUG "Compile daemon binary with debugging symbols" OFF)


set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME "feedreader")
set (DAEMON_NAME ${EXEC_NAME}-daemon)
set (DEBUG_NAME ${EXEC_NAME}-debug)
set (WEBEXTENSION_NAME webextension)
set (RELEASE_NAME "FeedReader")
set (VERSION "1.6")

find_package(PkgConfig)
find_package(Vala REQUIRED)
include(ValaVersion)
include(ValaPrecompile)
ensure_vala_version("0.30" MINIMUM)

pkg_check_modules(LIBUNITY QUIET unity)

add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
add_subdirectory (schemas)
add_subdirectory (libVilistextum)

include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/GitSHA1.vala.in" "${CMAKE_SOURCE_DIR}/GitSHA1.vala" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/InstallPrefix.vala.in" "${CMAKE_SOURCE_DIR}/InstallPrefix.vala" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service.in" "${CMAKE_SOURCE_DIR}/data/feedreader.service" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.appdata.xml.in" "${CMAKE_SOURCE_DIR}/data/feedreader.appdata.xml" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop.in" "${CMAKE_SOURCE_DIR}/data/feedreader.desktop" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop.in" "${CMAKE_SOURCE_DIR}/data/feedreader-autostart.desktop" @ONLY)


set(MODULES gtk+-3.0 json-glib-1.0 gee-0.8 libsoup-2.4 sqlite3 libsecret-1 libnotify libxml-2.0 rest-0.7 webkit2gtk-4.0 gstreamer-1.0 gstreamer-pbutils-1.0 goa-1.0)

if(LIBUNITY_FOUND)
	list(APPEND MODULES unity)
	message(STATUS "libunity: ON")
endif(LIBUNITY_FOUND)

pkg_check_modules(DEPS REQUIRED ${MODULES})

add_definitions(${DEPS_CFLAGS} -DGOA_API_IS_SUBJECT_TO_CHANGE)
link_libraries(${DEPS_LIBRARIES} -lm)
link_directories(${DEPS_LIBRARY_DIRS})

add_subdirectory (WebExtension)
add_subdirectory (libgtkimageview)
add_subdirectory (libgd)

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
    rest-0.7
    WebKit2-4.0
    gstreamer-1.0
    gstreamer-pbutils-1.0
    goa-1.0)

vala_precompile(UI ${EXEC_NAME}
    GitSHA1.vala
    InstallPrefix.vala
    src/DBusConnection.vala
    src/FeedReader.vala
    src/Logger.vala
    src/Backends/ttrss/ttrssUtils.vala
    src/Backends/owncloud/OwncloudNewsUtils.vala
    src/Backends/inoreader/InoReaderUtils.vala
    src/Backends/feedly/FeedlyUtils.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/InterfaceState.vala
    src/Model/ShareAccount.vala
    src/Constants.vala
    src/dbBase.vala
    src/dbUI.vala
    src/UiUtils.vala
    src/Utils.vala
    src/QueryBuilder.vala
    src/Widgets/AddPopover.vala
    src/Widgets/ArticleList.vala
    src/Widgets/ArticleRow.vala
    src/Widgets/ArticleView.vala
    src/Widgets/CategorieRow.vala
    src/Widgets/ColorCircle.vala
    src/Widgets/ColorPopover.vala
    src/Widgets/ContentPage.vala
    src/Widgets/FeedList.vala
    src/Widgets/FeedListFooter.vala
    src/Widgets/FeedRow.vala
    src/Widgets/FullscreenButton.vala
    src/Widgets/FullscreenHeaderbar.vala
    src/Widgets/HoverButton.vala
    src/Widgets/ImagePopup.vala
    src/Widgets/InAppNotification.vala
    src/Widgets/LoginPage.vala
    src/Widgets/MainWindow.vala
    src/Widgets/MediaPlayer.vala
    src/Widgets/MediaPopover.vala
    src/Widgets/MediaRow.vala
    src/Widgets/ModeButton.vala
    src/Widgets/ReaderHeaderbar.vala
    src/Widgets/RemovePopover.vala
    src/Widgets/ResetPage.vala
    src/Widgets/ServiceSettingsPopover.vala
    src/Widgets/ServiceSettingsRow.vala
    src/Widgets/ShareRow.vala
    src/Widgets/ShortcutsWindow.vala
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
    src/Share/Email.vala
    src/Share/PocketAPI.vala
    src/Share/InstapaperAPI.vala
    src/Share/ReadabilityAPI.vala
    src/Share/share.vala

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
target_link_libraries(${EXEC_NAME} gtkimageview)
target_link_libraries(${EXEC_NAME} gd)


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

if(LIBUNITY_FOUND)
	list(APPEND DAEMON_OPTIONS --define WITH_LIBUNITY)
	list(APPEND DAEMON_PACKAGES unity)
endif(LIBUNITY_FOUND)

if(WITH_DEBUG)
	list(APPEND DAEMON_OPTIONS -g)
endif(WITH_DEBUG)

vala_precompile(daemon ${DAEMON_NAME}
    InstallPrefix.vala
    src/Constants.vala
    src/Daemon.vala
    src/dbBase.vala
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
    src/Backends/OPMLparser.vala
    src/Backends/ttrss/ttrssAPI.vala
    src/Backends/ttrss/ttrssUtils.vala
    src/Backends/ttrss/ttrssMessage.vala
    src/Backends/feedly/FeedlyAPI.vala
    src/Backends/feedly/FeedlyConnection.vala
    src/Backends/feedly/FeedlyUtils.vala
    src/Backends/inoreader/InoReaderAPI.vala
    src/Backends/inoreader/InoReaderConnection.vala
    src/Backends/inoreader/InoReaderUtils.vala
    src/Backends/owncloud/OwncloudNewsAPI.vala
    src/Backends/owncloud/OwncloudNewsMessage.vala
    src/Backends/owncloud/OwncloudNewsUtils.vala
    src/ContentGrabber/stringPair.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
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

vala_precompile(debug ${DEBUG_NAME}
    src/dbBase.vala
    src/dbDaemon.vala
    src/Logger.vala
    src/Utils.vala
    src/OfflineActionManager.vala
    src/QueryBuilder.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/InterfaceState.vala
    src/Model/OfflineAction.vala
    src/Constants.vala
    src/Backends/FeedServer.vala
    src/Backends/OPMLparser.vala
    src/Backends/ttrss/ttrssAPI.vala
    src/Backends/ttrss/ttrssUtils.vala
    src/Backends/ttrss/ttrssMessage.vala
    src/Backends/feedly/FeedlyAPI.vala
    src/Backends/feedly/FeedlyConnection.vala
    src/Backends/feedly/FeedlyUtils.vala
    src/Backends/inoreader/InoReaderAPI.vala
    src/Backends/inoreader/InoReaderConnection.vala
    src/Backends/inoreader/InoReaderUtils.vala
    src/Backends/owncloud/OwncloudNewsAPI.vala
    src/Backends/owncloud/OwncloudNewsMessage.vala
    src/Backends/owncloud/OwncloudNewsUtils.vala
    src/ContentGrabber/stringPair.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
    src/Debug/DebugServer.vala
    src/Debug/DebugUtils.vala
    InstallPrefix.vala


PACKAGES
    glib-2.0>=2.32
    gtk+-3.0
    gio-2.0
    sqlite3
    gee-0.8
    libsoup-2.4
    json-glib-1.0
    libsecret-1
    libxml-2.0
    libnotify

OPTIONS
    --target-glib=2.32

CUSTOM_VAPIS
    vapi/libvilistextum.vapi
)

add_executable(${DEBUG_NAME} ${debug})
target_link_libraries(${DEBUG_NAME} vilistextum)


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
install (FILES ${PROJECT_BINARY_DIR}/WebExtension/libwebextension.so DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service DESTINATION ${DATADIR}/dbus-1/services/)
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/icons/hicolor DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons)
install (CODE "execute_process (COMMAND gtk-update-icon-cache -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/shortcuts.ui DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/ArticleView DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/GrabberConfig DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/gtk-css DESTINATION ${PKGDATADIR})
