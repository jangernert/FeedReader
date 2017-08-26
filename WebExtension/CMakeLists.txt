vala_precompile(webext webextension
	webextension.vala

PACKAGES
	libsoup-2.4
	gtk+-3.0
	webkit2gtk-web-extension-4.0

OPTIONS
	--vapidir=${CMAKE_SOURCE_DIR}/vapi/
)

add_library(webextension SHARED ${webext})
