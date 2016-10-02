project (FeedReader)
cmake_minimum_required (VERSION 2.6)
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
include_directories(${CMAKE_SOURCE_DIR}/libVilistextum)
include_directories(${CMAKE_SOURCE_DIR}/libgtkimageview)
include_directories(${CMAKE_SOURCE_DIR})

add_definitions("-w")

set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (UI_NAME "feedreader")
set (DAEMON_NAME ${UI_NAME}-daemon)
set (WEBEXTENSION_NAME webextension)
set (RELEASE_NAME "FeedReader")
set (VERSION "2.0-dev")
set (GLIB_VERSION 2.40)

find_package(PkgConfig)
find_package(Vala REQUIRED)
include(ValaVersion)
include(ValaPrecompile)
include(GResource)
ensure_vala_version("0.30" MINIMUM)

pkg_check_modules(LIBUNITY QUIET unity)

add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
add_subdirectory (schemas)
add_subdirectory (libVilistextum)

include(GetGitRevisionDescription)
get_git_head_revision(GIT_REFSPEC GIT_SHA1)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/Constants.vala.in" "${CMAKE_SOURCE_DIR}/Constants.vala" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service.in" "${CMAKE_SOURCE_DIR}/data/feedreader.service" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.appdata.xml.in" "${CMAKE_SOURCE_DIR}/data/feedreader.appdata.xml" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop.in" "${CMAKE_SOURCE_DIR}/data/feedreader.desktop" @ONLY)
configure_file("${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop.in" "${CMAKE_SOURCE_DIR}/data/feedreader-autostart.desktop" @ONLY)


set(MODULES 
	gtk+-3.0>=3.20
	json-glib-1.0
	gee-0.8
	libsoup-2.4
	sqlite3
	libsecret-1
	libnotify
	libxml-2.0
	rest-0.7
	webkit2gtk-4.0
	gstreamer-1.0
	gstreamer-pbutils-1.0
	goa-1.0
	libpeas-1.0
	libcurl)

if(LIBUNITY_FOUND)
	list(APPEND MODULES unity)
	message(STATUS "libunity: ON")
endif(LIBUNITY_FOUND)

pkg_check_modules(DEPS REQUIRED ${MODULES})

add_definitions(${DEPS_CFLAGS} -DGOA_API_IS_SUBJECT_TO_CHANGE)
link_libraries(${DEPS_LIBRARIES} -lm)
link_directories(${DEPS_LIBRARY_DIRS})

add_subdirectory(WebExtension)
add_subdirectory(libgtkimageview)
add_subdirectory(libgd)


################################################################################


vala_precompile(LIBFR libFeedReader
    src/Common.vala
    src/Logger.vala
    src/Enums.vala
    src/dbBase.vala
    src/Utils.vala
    src/QueryBuilder.vala
    src/ContentGrabber/stringPair.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Model/OfflineAction.vala
    src/Model/InterfaceState.vala
    src/Model/ShareAccount.vala
    Constants.vala

PACKAGES
    gee-0.8
    libsecret-1
    sqlite3
    libsoup-2.4

OPTIONS
    --target-glib=${GLIB_VERSION}
    --vapi=FeedReaderCommon.vapi
    --header=FeedReaderCommon.h
    
CUSTOM_VAPIS
    vapi/libvilistextum.vapi
)

add_library(FeedReaderCommon STATIC ${LIBFR})
target_link_libraries(FeedReaderCommon vilistextum)


################################################################################

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
    goa-1.0
    libpeas-1.0)

vala_precompile(UI ${UI_NAME}
    Constants.vala
    src/DBusConnection.vala
    src/FeedReader.vala
    src/LoginInterface.vala
    src/dbUI.vala
    src/UtilsUI.vala
    src/Widgets/AddPopover.vala
    src/Widgets/ArticleList.vala
    src/Widgets/ArticleRow.vala
    src/Widgets/ArticleView.vala
    src/Widgets/BackendInfoPopover.vala
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
    src/Widgets/LoginRow.vala
    src/Widgets/MainWindow.vala
    src/Widgets/MediaPlayer.vala
    src/Widgets/MediaPopover.vala
    src/Widgets/MediaRow.vala
    src/Widgets/ModeButton.vala
    src/Widgets/ReaderHeaderbar.vala
    src/Widgets/RemovePopover.vala
    src/Widgets/ResetPage.vala
    src/Widgets/ServiceSettingsPopover.vala
    src/Widgets/ShareRow.vala
    src/Widgets/ShortcutsWindow.vala
    src/Widgets/ServiceInfo.vala
    src/Widgets/Setting.vala
    src/Widgets/SettingsDialog.vala
    src/Widgets/SharePopover.vala
    src/Widgets/SimpleHeader.vala
    src/Widgets/SpringCleanPage.vala
    src/Widgets/TagRow.vala
    src/Widgets/TagPopover.vala
    src/Widgets/TagPopoverRow.vala
    src/Widgets/UpdateButton.vala
    src/Widgets/WebLoginPage.vala
    src/Share/share.vala
    src/Share/ServiceSetup.vala
    src/Share/ShareAccountInterface.vala

PACKAGES
    ${UI_PACKAGES}

OPTIONS
    --target-glib=${GLIB_VERSION}
    --header=FeedReaderUI.h
    --vapi=FeedReaderUI.vapi
    --enable-experimental

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
    vapi/libvilistextum.vapi
    vapi/gtkimageview.vapi
    vapi/gd-1.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE data/feedreader.gresource.xml)

add_executable(${UI_NAME} ${UI} ${GRESOURCES})
target_link_libraries(${UI_NAME} vilistextum gtkimageview gd FeedReaderCommon)


################################################################################


set(DAEMON_OPTIONS
    --target-glib=${GLIB_VERSION}
    --header=FeedReader.h
    --vapi=FeedReader.vapi)
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
    rest-0.7
    libpeas-1.0)

if(LIBUNITY_FOUND)
	list(APPEND DAEMON_OPTIONS --define WITH_LIBUNITY)
	list(APPEND DAEMON_PACKAGES unity)
endif(LIBUNITY_FOUND)

vala_precompile(daemon ${DAEMON_NAME}
    src/Daemon.vala
    src/dbDaemon.vala
    src/OfflineActionManager.vala
    src/Backend/FeedServer.vala
    src/Backend/FeedServerInterface.vala
    src/Backend/OPMLparser.vala
    src/ContentGrabber/grabberConfig.vala
    src/ContentGrabber/grabber.vala
    src/ContentGrabber/grabberUtils.vala
    Constants.vala


PACKAGES
    ${DAEMON_PACKAGES}

OPTIONS
    ${DAEMON_OPTIONS}

CUSTOM_VAPIS
    vapi/libvilistextum.vapi
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
)

add_executable(${DAEMON_NAME} ${daemon})
target_link_libraries(${DAEMON_NAME} vilistextum FeedReaderCommon)


################################################################################


add_dependencies(${DAEMON_NAME} FeedReaderCommon)
add_dependencies(${UI_NAME} FeedReaderCommon)


# build plugins
add_subdirectory(plugins)


################################################################################


# uninstall target
configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/cmake/uninstall.cmake"
    "${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake"
    IMMEDIATE @ONLY)

add_custom_target(uninstall
    COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_BINARY_DIR}/uninstall.cmake)

install (TARGETS ${UI_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${DAEMON_NAME} RUNTIME DESTINATION bin)
install (FILES ${PROJECT_BINARY_DIR}/WebExtension/libwebextension.so DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service DESTINATION ${DATADIR}/dbus-1/services/)
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/application-icons/hicolor DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons)
install (CODE "execute_process (COMMAND gtk-update-icon-cache -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop DESTINATION ${PKGDATADIR})
install (DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/data/GrabberConfig DESTINATION ${PKGDATADIR})
