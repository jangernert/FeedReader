# - Try to find the libesmtp library
# Once done this will define
#
#  CURL_FOUND - system has the libesmtp library
#  CURL_CONFIG
#  CURL_INCLUDE_DIR - the libesmtp include directory
#  CURL_LIBRARIES - The libraries needed to use libesmtp
#
# Based on FindESMTP.cmake
# Distributed under the BSD license.

if (CURL_LIBRARIES)
	# Already in cache, be silent
	set(CURL_FIND_QUIETLY TRUE)
endif (CURL_LIBRARIES)

FIND_PROGRAM(CURL_CONFIG curl-config)

IF (CURL_CONFIG)
	EXEC_PROGRAM(${CURL_CONFIG} ARGS --libs OUTPUT_VARIABLE _CURL_LIBRARIES)
	string(REGEX REPLACE "[\r\n]" " " _CURL_LIBRARIES "${_CURL_LIBRARIES}")
	set (CURL_LIBRARIES ${_CURL_LIBRARIES} CACHE STRING "The libraries needed for Curl")
ENDIF (CURL_CONFIG)

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(CURL DEFAULT_MSG CURL_LIBRARIES )

MARK_AS_ADVANCED(CURL_LIBRARIES)

