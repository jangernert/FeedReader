add_library(vilistextum STATIC
	charset.h
	charset.c
	fileio.h
	fileio.c
	html.h
	html.c
	html_tag.h
	html_tag.c
	latin1.h
	latin1.c
	lists.h
	lists.c
	microsoft.h
	microsoft.c
	multibyte.h
	text.h
	text.c
	unicode_entities.h
	unicode_entities.c
	util.h
	util.c
	vilistextum.h
	vilistextum.c)
set_property(TARGET vilistextum PROPERTY POSITION_INDEPENDENT_CODE ON)
