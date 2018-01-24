set (PLUGNAME local)
set (PLUGTARGET ${PLUGNAME}_target)

find_package(GLIB REQUIRED)
find_package(Curl REQUIRED)
include_directories(${GLIB_INCLUDE_DIRS})
include_directories(rss-glib)

add_subdirectory(libnxml)
add_subdirectory(libmrss)
add_subdirectory(rss-glib)

# ----------------------------------------------------------
# Daemon Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${PLUGTARGET}
	localInterface.vala
	localUtils.vala
	SuggestedFeedRow.vala

PACKAGES
	libpeas-1.0
	json-glib-1.0
	gtk+-3.0
	libsoup-2.4
	gee-0.8
	libxml-2.0
	sqlite3
	libsecret-1
	webkit2gtk-4.0

OPTIONS
	--target-glib=2.32
	--library ${PLUGNAME}

CUSTOM_VAPIS
	${CMAKE_BINARY_DIR}/FeedReader.vapi
	${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
	rss-glib/rss-glib-1.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE ${PLUGNAME}.gresource.xml)

add_library(${PLUGNAME} SHARED ${VALA_C} ${GRESOURCES})
target_link_libraries(${PLUGNAME} gobject-2.0 glib-2.0 curl rss-glib mrss nxml)

# ----------------------------------------------------------


add_dependencies(${PLUGNAME} ${UI_NAME} ${FEEDREADER_NAME})

install(TARGETS ${PLUGNAME} DESTINATION ${PKGLIBDIR}/plugins)
install(FILES ${PLUGNAME}.plugin DESTINATION ${PKGLIBDIR}/plugins)

