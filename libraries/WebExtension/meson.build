webkit2gtk_vapi    = vala_compiler.find_library('webkit2gtk-web-extension-4.0',
                                                dirs: VAPI_DIR)

webextension_lib = shared_library(
  'webextension',
  [
    'webextension.vala'
  ],
  dependencies: [
    gtk,
    libsoup,
    webkitextension
  ]
)

lib_webextension = declare_dependency(
  link_with: webextension_lib,
)
