set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
find_package(GLIB)
include_directories(${GLIB_INCLUDE_DIRS})
include_directories(../libmrss)

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
