vilistextum_inc = include_directories('.')
vilistextum_lib = static_library(
  'vilistextum',
  [
    'charset.c',
    'fileio.c',
    'html.c',
    'html_tag.c',
    'latin1.c',
    'lists.c',
    'microsoft.c',
    'text.h',
    'text.c',
    'unicode_entities.c',
    'util.c',
    'vilistextum.c'
  ]
)

vilistextum_main = executable(
	'vilistextum_main',
	'main.c',
	link_with: vilistextum_lib)

vilistextum_test = executable(
	'vilistextum_test',
	'test.c',
	link_with: vilistextum_lib,
	dependencies: [ glib ])


if gtester.found()
    test('Vilistextum', gtester, args:['-k', '-o', meson.build_root() + '/vilistextum.gtester.log', vilistextum_test])
else
    test('Vilistextum', vilistextum_test)
endif
