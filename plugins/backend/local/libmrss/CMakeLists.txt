set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)
include_directories(../libnxml)

add_library(mrss STATIC
	mrss.h
	mrss_download.c
	mrss_edit.c
	mrss_free.c
	mrss_generic.c
	mrss_internal.h
	mrss_options.c
	mrss_parser.c
	mrss_search.c
	mrss_write.c)
