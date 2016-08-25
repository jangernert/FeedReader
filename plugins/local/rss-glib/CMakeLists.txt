set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)
find_package(GLIB)
include_directories(${GLIB_INCLUDE_DIRS})

add_library(rss-glib STATIC
	rss-document.c
	rss-document.h
	rss-document-private.h
	rss-marshal.c
	rss-marshal.h
	rss-glib.h
	rss-item.c
	rss-item.h
	rss-item-private.h
	rss-parser.c
	rss-parser.h
	rss-parser-private.h
	rss-version.h)
