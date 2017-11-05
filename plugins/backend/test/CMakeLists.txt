set (NAME TestPlugin)
set (TARGET ${NAME}_target)

vala_precompile(VALA_C ${TARGET}
	TestPlugin.vala

PACKAGES
	libpeas-1.0
	gtk+-3.0
	json-glib-1.0
	libsoup-2.4
	gee-0.8
	libxml-2.0
	sqlite3
	libsecret-1

GENERATE_VAPI ${NAME}

OPTIONS
	--target-glib=2.32
	--library ${NAME}

CUSTOM_VAPIS
	${CMAKE_BINARY_DIR}/FeedReader.vapi
	${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
	${CMAKE_SOURCE_DIR}/vapi/webkit2gtk-4.0.vapi
)

add_library(${NAME} STATIC ${VALA_C})
set_property(TARGET ${NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)

# ----------------------------------------------------------

add_dependencies(${NAME} ${FEEDREADER_NAME})
