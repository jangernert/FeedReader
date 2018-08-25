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
	'vilistextum_main.c',
	link_with: vilistextum_lib)

if afl_fuzz.found()
	test('Fuzz libvilistexum', afl_fuzz, args:['-d', vilistextum_main])
endif
