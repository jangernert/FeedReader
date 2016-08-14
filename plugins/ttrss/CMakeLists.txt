

vala_precompile(VALA_C ttrss_plugin
    ttrssAPI.vala
    ttrssInterface.vala
    ttrssMessage.vala
    ttrssUtils.vala


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
    --library ttrss

CUSTOM_VAPIS
    ${CMAKE_BINARY_DIR}/FeedReader.vapi
)

add_library(ttrss SHARED ${VALA_C})

install(TARGETS ttrss DESTINATION ${PKGDATADIR}/plugins)
install(FILES ttrss.plugin DESTINATION ${PKGDATADIR}/plugins)
add_schema("org.gnome.feedreader.ttrss.gschema.xml")
