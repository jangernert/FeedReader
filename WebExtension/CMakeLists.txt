set(WEBEXT_PACKAGES libsoup-2.4 gtk+-3.0)

if(WEBKITGTK4_FOUND)
	list(APPEND WEBEXT_PACKAGES webkit2gtk-web-extension-4.0)
else(WEBKITGTK4_FOUND)
	list(APPEND WEBEXT_PACKAGES webkit2gtk-web-extension-3.0)
endif(WEBKITGTK4_FOUND)

vala_precompile(webext webextension
    webextension.vala

PACKAGES
    ${WEBEXT_PACKAGES}

OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi/
)

add_library(webextension SHARED ${webext})
