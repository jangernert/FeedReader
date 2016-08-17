set (NAME feedly)
set (TARGETNAME ${NAME}_target)

vala_precompile(VALA_C ${TARGETNAME}
    feedlyAPI.vala
    feedlyConnection.vala
    feedlyInterface.vala
    feedlyUtils.vala


PACKAGES
    libpeas-1.0
    json-glib-1.0
    libsoup-2.4
    gee-0.8
    libxml-2.0
    sqlite3
    libsecret-1

OPTIONS
    --target-glib=2.32
    --library ${NAME}

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReader.vapi
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
)

add_library(${NAME} SHARED ${VALA_C})

add_dependencies(${NAME} ${EXEC_NAME} ${DAEMON_NAME})

add_schema("org.gnome.feedreader.${NAME}.gschema.xml")

install(TARGETS ${NAME} DESTINATION ${PKGDATADIR}/plugins)
install(FILES ${NAME}.plugin DESTINATION ${PKGDATADIR}/plugins)
install (DIRECTORY icons/hicolor/ DESTINATION ${CMAKE_INSTALL_PREFIX}/share/icons)
install(CODE "execute_process (COMMAND gtk-update-icon-cache -t ${CMAKE_INSTALL_PREFIX}/share/icons/hicolor)")

