set (NAME pocket)
set (PLUGTARGET ${NAME}_target)

# ----------------------------------------------------------
# Daemon Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${PLUGTARGET}
    PocketAPI.vala
    PocketSetup.vala

PACKAGES
    libpeas-1.0
    gtk+-3.0
    gee-0.8
    libsecret-1
    sqlite3
    libsoup-2.4
    WebKit2-4.0
    rest-0.7
    json-glib-1.0

OPTIONS
    --target-glib=2.32
    --library ${NAME}

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReaderUI.vapi
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
    ${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
)

add_library(${NAME} SHARED ${VALA_C})
add_dependencies(${NAME} ${EXEC_NAME} ${DAEMON_NAME})

install(TARGETS ${NAME} DESTINATION ${PKGDATADIR}/pluginsShare)
install(FILES ${NAME}.plugin DESTINATION ${PKGDATADIR}/pluginsShare)
install (DIRECTORY icons/hicolor/ DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)
install(CODE "execute_process (COMMAND gtk-update-icon-cache -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")

