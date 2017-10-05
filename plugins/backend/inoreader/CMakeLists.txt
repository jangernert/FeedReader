set (PLUGNAME inoreader)
set (PLUGTARGET ${PLUGNAME}_target)

# ----------------------------------------------------------
# Daemon Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${PLUGTARGET}
	InoReaderAPI.vala
	InoReaderInterface.vala
	InoReaderUtils.vala
	InoReaderConnection.vala

PACKAGES
	libpeas-1.0
	gtk+-3.0
	json-glib-1.0
	libsoup-2.4
	gee-0.8
	libxml-2.0
	sqlite3
	libsecret-1

OPTIONS
	--target-glib=2.32
	--library ${PLUGNAME}

CUSTOM_VAPIS
	${CMAKE_BINARY_DIR}/FeedReader.vapi
	${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
	${CMAKE_SOURCE_DIR}/vapi/webkit2gtk-4.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE ${PLUGNAME}.gresource.xml)
add_library(${PLUGNAME} SHARED ${VALA_C} ${GRESOURCES})

# ----------------------------------------------------------


add_dependencies(${PLUGNAME} ${PLUGNAME} ${FEEDREADER_NAME})

add_schema("org.gnome.feedreader.${PLUGNAME}.gschema.xml")

install(TARGETS ${PLUGNAME} DESTINATION ${PKGLIBDIR}/plugins)
install(FILES ${PLUGNAME}.plugin DESTINATION ${PKGLIBDIR}/plugins)
