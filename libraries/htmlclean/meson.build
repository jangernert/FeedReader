htmlclean_inc = include_directories('.')
htmlclean_lib = static_library(
  'htmlclean',
  [
    'htmlclean.c'
  ],
  dependencies: [ glib, gumbo ]
)

htmlclean_main = executable(
	'htmlclean_main',
	'main.c',
	link_with: htmlclean_lib)

htmlclean_test = executable(
  'test_htmlclean',
  [
    'test_htmlclean.c'
  ],
  dependencies: [
    glib,
    gtk
  ],
  link_with: htmlclean_lib
)

if gtester.found()
    test('Htmlclean library', gtester, args:['-k', '-o', meson.build_root() + '/htmlclean.gtester.log', htmlclean_test])
else
    test('Htmlclean library', htmlclean_test)
endif
