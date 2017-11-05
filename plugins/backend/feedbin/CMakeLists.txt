set (PLUGNAME feedbin)
set (PLUGTARGET ${PLUGNAME}_target)

set (TEST_NAME ${PLUGNAME}_test)
set (TEST_TARGET ${TEST_NAME}_target)

# ----------------------------------------------------------
# Feedbin Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${PLUGTARGET}
	feedbinAPI.vala
	feedbinInterface.vala
	feedbinUtils.vala

GENERATE_VAPI FeedbinPlugin

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

add_dependencies(${PLUGNAME} ${FEEDREADER_NAME})
add_schema("org.gnome.feedreader.${PLUGNAME}.gschema.xml")

install(TARGETS ${PLUGNAME} DESTINATION ${PKGLIBDIR}/plugins)
install(FILES ${PLUGNAME}.plugin DESTINATION ${PKGLIBDIR}/plugins)

# ----------------------------------------------------------
# Tests
# ----------------------------------------------------------

vala_precompile(VALA_C ${TEST_TARGET}
	TestFeedbin.vala

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
	--includedir=${CMAKE_BINARY_DIR}/plugins/backend/test/
	--target-glib=2.32
	--disable-warnings # since we frequently want to not catch errors

CUSTOM_VAPIS
	${CMAKE_BINARY_DIR}/FeedReader.vapi
	${CMAKE_BINARY_DIR}/plugins/backend/feedbin/FeedbinPlugin.vapi
	${CMAKE_BINARY_DIR}/plugins/backend/test/TestPlugin.vapi
	${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
	${CMAKE_SOURCE_DIR}/vapi/webkit2gtk-4.0.vapi
)

add_executable(${TEST_NAME} ${VALA_C})
target_link_libraries(${TEST_NAME} ${PLUGNAME} TestPlugin)

add_test(${PLUGNAME} gtester -k -o ${CMAKE_BINARY_DIR}/${PLUGNAME}.gtester.log ${TEST_NAME})
