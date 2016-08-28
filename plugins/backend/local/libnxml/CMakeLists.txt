set(CMAKE_POSITION_INDEPENDENT_CODE TRUE)

add_library(nxml STATIC
	nxml.h
	nxml_download.c
	nxml_easy.c
	nxml_edit.c
	nxml_error.c
	nxml_free.c
	nxml_init.c
	nxml_internal.h
	nxml_namespace.c
	nxml_parser.c
	nxml_string.c
	nxml_tools.c
	nxml_utf.c
	nxml_write.c)
