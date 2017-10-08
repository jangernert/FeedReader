supported_share_plugins = [
  'Browser',
  'Email',
  'Instapaper',
  'Pocket',
  'Telegram',
  'Twitter',
  'Wallabag'
]

share_plugins = get_option('share-plugins').to_lower().split(',')

foreach share_plugin: supported_share_plugins
  if share_plugins.contains(share_plugin.to_lower())
    message('Share Plugin: ' + share_plugin + ' is ON')
    subdir(share_plugin)
  else
    message('Share Plugin: ' + share_plugin + ' is OFF')
  endif
endforeach
