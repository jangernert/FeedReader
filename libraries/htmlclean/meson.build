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
