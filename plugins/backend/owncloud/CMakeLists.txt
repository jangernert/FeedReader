set (NAME owncloud)

set (UINAME ${NAME}UI)
set (DAEMONTARGET ${NAME}_target)
set (UITARGET ${UINAME}_target)

# ----------------------------------------------------------
# Daemon Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${DAEMONTARGET}
    OwncloudNewsAPI.vala
    OwncloudNewsInterface.vala
    OwncloudNewsMessage.vala
    OwncloudNewsUtils.vala

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
target_link_libraries(${NAME} FeedReaderCommon)


# ----------------------------------------------------------
# UI Plugin
# ----------------------------------------------------------


vala_precompile(VALA_C2 ${UITARGET}
    OwncloudNewsLoginWidget.vala
    OwncloudNewsUtils.vala

PACKAGES
    libpeas-1.0
    gtk+-3.0
    gee-0.8
    libsecret-1
    sqlite3
    libsoup-2.4
    WebKit2-4.0
    libxml-2.0

OPTIONS
    --target-glib=2.32
    --library ${NAME}

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReaderUI.vapi
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
    ${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
    ${CMAKE_SOURCE_DIR}/vapi/webkit2gtk-4.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE ${NAME}.gresource.xml)

add_library(${UINAME} SHARED ${VALA_C2} ${GRESOURCES})


# ----------------------------------------------------------


add_dependencies(${NAME} ${UI_NAME} ${DAEMON_NAME})
add_dependencies(${UINAME} ${UI_NAME} ${DAEMON_NAME})

add_schema("org.gnome.feedreader.${NAME}.gschema.xml")

install(TARGETS ${NAME} DESTINATION ${PKGLIBDIR}/plugins)
install(TARGETS ${UINAME} DESTINATION ${PKGLIBDIR}/pluginsUI)
install(FILES ${NAME}.plugin DESTINATION ${PKGLIBDIR}/plugins)
install(FILES ${UINAME}.plugin DESTINATION ${PKGLIBDIR}/pluginsUI)
