webkit2gtk_vapi    = vala_compiler.find_library('webkit2gtk-web-extension-4.0',
                                                dirs: VAPI_DIR)
webkit2gtk_ext_lib = declare_dependency(dependencies: webkit2gtk_vapi)


shared_library('webextension',
  [
    'webextension.vala'
  ],
  dependencies: [
    gtk,
    libsoup,
    webkit2gtk_ext_lib
  ]
)
