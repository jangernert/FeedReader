supported_backend_plugins = [
  'bazqux',
  'demo',
  'feedbin',
  'feedhq',
  'feedly',
  'fresh',
  'inoreader',
  'local',
  'oldreader',
  'owncloud',
  'ttrss'
]
backend_plugins = get_option('backend-plugins').to_lower().split(',')

foreach backend_plugin: supported_backend_plugins
  if backend_plugins.contains(backend_plugin.to_lower())
    message('Backend Plugin: ' + backend_plugin + ' is ON')
    subdir(backend_plugin)
  else
    message('Backend Plugin: ' + backend_plugin + ' is OFF')
  endif
endforeach
