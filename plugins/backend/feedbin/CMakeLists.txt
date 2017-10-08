set (PLUGNAME feedbin)
set (PLUGTARGET ${PLUGNAME}_target)

set (API_NAME ${PLUGNAME}API)
set (API_TARGET ${API_NAME}_target)

set (TEST_NAME ${PLUGNAME}_test)
set (TEST_TARGET ${TEST_NAME}_target)

# ----------------------------------------------------------
# Feedbin API Library
# ----------------------------------------------------------

vala_precompile(VALA_C ${API_TARGET}
	feedbinAPI.vala

GENERATE_VAPI
	feedbinAPI

PACKAGES
	json-glib-1.0
	libsoup-2.4
	gee-0.8

OPTIONS
	--target-glib=2.32
	--library ${API_NAME}
)

add_library(${API_NAME} STATIC ${VALA_C})
set_property(TARGET ${API_NAME} PROPERTY POSITION_INDEPENDENT_CODE ON)

# ----------------------------------------------------------
# Feedbin Plugin
# ----------------------------------------------------------

vala_precompile(VALA_C ${PLUGTARGET}
	feedbinInterface.vala
	feedbinUtils.vala

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
	${CMAKE_BINARY_DIR}/plugins/backend/feedbin/feedbinAPI.vapi
	${CMAKE_SOURCE_DIR}/vapi/gd-1.0.vapi
	${CMAKE_SOURCE_DIR}/vapi/webkit2gtk-4.0.vapi
)

GLIB_COMPILE_RESOURCES(GRESOURCES SOURCE ${PLUGNAME}.gresource.xml)

add_library(${PLUGNAME} SHARED ${VALA_C} ${GRESOURCES})
target_link_libraries(${PLUGNAME} ${API_NAME})

# ----------------------------------------------------------

add_dependencies(${PLUGNAME} ${UI_NAME} ${FEEDREADER_NAME})
add_schema("org.gnome.feedreader.${PLUGNAME}.gschema.xml")

# ----------------------------------------------------------
# Tests
# ----------------------------------------------------------

install(TARGETS ${PLUGNAME} DESTINATION ${PKGLIBDIR}/plugins)
install(FILES ${PLUGNAME}.plugin DESTINATION ${PKGLIBDIR}/plugins)
vala_precompile(VALA_C ${TEST_TARGET}
	TestFeedbin.vala

PACKAGES
	json-glib-1.0
	libsoup-2.4
	gee-0.8

OPTIONS
	--target-glib=2.32

CUSTOM_VAPIS
	${CMAKE_BINARY_DIR}/plugins/backend/feedbin/feedbinAPI.vapi
)

add_executable(${TEST_NAME} ${VALA_C})
target_link_libraries(${TEST_NAME} ${API_NAME})

add_test(${PLUGNAME} gtester -k -o ${CMAKE_BINARY_DIR}/${PLUGNAME}.gtester.log ${TEST_NAME})
