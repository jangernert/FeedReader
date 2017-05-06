vala_precompile(ivy Ivy
	Extractor.vala
	Frame.vala
	Printer.vala
	Stacktrace.vala

PACKAGES
	linux
	gee-0.8
	posix
	
GENERATE_VAPI
	ivy
)


add_library(ivy STATIC
	Extractor.c
	Frame.c
	Printer.c
	Stacktrace.c
	)
set_property(TARGET ivy PROPERTY POSITION_INDEPENDENT_CODE ON)
