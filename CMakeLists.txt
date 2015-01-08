project (RSSReader)
cmake_minimum_required (VERSION 2.6)


list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)


set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/FeedReader")
set (GETTEXT_PACKAGE ${CMAKE_PROJECT_NAME})
set (EXEC_NAME "feedreader")
set (DAEMON_NAME ${EXEC_NAME}-daemon)
set (RELEASE_NAME "RSS Client")
set (VERSION "0.01")
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
    src/feedreader.vala
    src/types.vala
    src/article-list.vala
    src/articlerow.vala
    src/article-view.vala
    src/baseRow.vala
    src/categorie-row.vala
    src/db-manager.vala
    src/feed-list.vala
    src/feed-row.vala
    src/login-dialog.vala
    src/reader-headerbar.vala
    src/ThinPaned.vala
    
    
    
    
    
    src/ui.vala
    src/update-button.vala

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
    src/daemon.vala
    src/db-manager.vala
    src/types.vala
    src/Constants.vala
    
    src/backends/feed_server.vala
    src/backends/tt-rss/ttrss_interface.vala
    src/backends/feedly/FeedlyAPI.vala
    src/backends/feedly/FeedlyConnection.vala


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
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/categorie_expander.png DESTINATION ${PKGDATADIR})
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/data/rss24.png DESTINATION ${PKGDATADIR})
