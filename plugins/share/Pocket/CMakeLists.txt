set (NAME pocket)
set (PLUGTARGET ${NAME}_target)



link_libraries(${POCKET_DEPS_LIBRARIES} -lm)
link_directories(${POCKET_DEPS_LIBRARY_DIRS})

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
    goa-1.0

OPTIONS
    --target-glib=2.32
    --library ${NAME}

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReaderUI.vapi
    ${CMAKE_BINARY_DIR}/FeedReaderCommon.vapi
    ${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE ${NAME}.gresource.xml)

add_library(${NAME} SHARED ${VALA_C} ${GRESOURCES})
add_dependencies(${NAME} ${UI_NAME} ${DAEMON_NAME})

install(TARGETS ${NAME} DESTINATION ${PKGLIBDIR}/pluginsShare)
install(FILES ${NAME}.plugin DESTINATION ${PKGLIBDIR}/pluginsShare)

