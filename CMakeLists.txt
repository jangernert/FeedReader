project (RSSReader)
cmake_minimum_required (VERSION 2.6)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)


set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME "feedreader")
set (DAEMON_NAME ${EXEC_NAME}-daemon)
set (RELEASE_NAME "RSS Client")
set (VERSION "0.2")
set (VERSION_INFO "whats up world")

find_package(PkgConfig)
add_definitions (-DGETTEXT_PACKAGE=\"${GETTEXT_PACKAGE}\")
add_subdirectory (po)
add_subdirectory (schemas)

pkg_check_modules(DEPS REQUIRED gtk+-3.0 json-glib-1.0 gee-0.8 libsoup-2.4 webkit2gtk-3.0 sqlite3 libsecret-1 libnotify unity)

add_definitions(${DEPS_CFLAGS})
link_libraries(${DEPS_LIBRARIES})
link_directories(${DEPS_LIBRARY_DIRS})

find_package(Vala REQUIRED)
include(ValaVersion)
ensure_vala_version("0.24" MINIMUM)

# files we want to compile
include(ValaPrecompile)
vala_precompile(UI ${EXEC_NAME}
    src/FeedReader.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Constants.vala
    src/DB_Manager.vala
    src/Widgets/ArticleList.vala
    src/Widgets/ArticleRow.vala
    src/Widgets/ArticleView.vala
    src/Widgets/BaseRow.vala
    src/Widgets/CategorieRow.vala
    src/Widgets/ColorCircle.vala
    src/Widgets/ColorPopover.vala
    src/Widgets/FeedList.vala
    src/Widgets/FeedRow.vala
    src/Widgets/LoginDialog.vala
    src/Widgets/MainWindow.vala
    src/Widgets/ReaderHeaderbar.vala
    src/Widgets/TagRow.vala
    src/Widgets/UpdateButton.vala
    src/Widgets/WebLogin.vala

# tell what libraries to use when compiling
PACKAGES
    glib-2.0>=2.32
    gtk+-3.0
    json-glib-1.0
    libsoup-2.4
    sqlite3
    WebKit2-3.0
    libsecret-1
    libnotify
    unity

OPTIONS
    --target-glib=2.32

)

vala_precompile(daemon ${DAEMON_NAME}
    src/Daemon.vala
    src/DB_Manager.vala
    src/Model/Feed.vala
    src/Model/Category.vala
    src/Model/Article.vala
    src/Model/Tag.vala
    src/Constants.vala
    src/Backends/FeedServer.vala
    src/Backends/ttrss/TTRSS_API.vala
    src/Backends/ttrss/TTRSS_Utils.vala
    src/Backends/ttrss/TTRSS_Message.vala
    src/Backends/feedly/FeedlyAPI.vala
    src/Backends/feedly/FeedlyConnection.vala


PACKAGES
    glib-2.0>=2.32
    gio-2.0
    sqlite3
    gee-0.8
    libsoup-2.4
    json-glib-1.0
    libnotify
    libsecret-1
    unity

OPTIONS
    --target-glib=2.32
    -g
)



# tell cmake what to call the executable we just made
add_executable(${EXEC_NAME} ${UI})
add_executable(${DAEMON_NAME} ${daemon})

# install the binaries we just made
install (TARGETS ${EXEC_NAME} RUNTIME DESTINATION bin)
install (TARGETS ${DAEMON_NAME} RUNTIME DESTINATION bin)

# install our .desktop file so the Applications menu will see it
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.desktop DESTINATION ${DATADIR}/applications/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader.service DESTINATION ${DATADIR}/dbus-1/services/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedreader-autostart.desktop DESTINATION $ENV{HOME}/.config/autostart/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/FeedReader.css DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/arrow-left.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/arrow-down.svg DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/feedly.png DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/owncloud.png DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/ttrss.png DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/rss24.svg DESTINATION ${PKGDATADIR})
