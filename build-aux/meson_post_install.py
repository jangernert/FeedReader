#!/usr/bin/env python3

from os import environ, path
from subprocess import call

prefix = environ.get('MESON_INSTALL_PREFIX', '/usr/local')
datadir = path.join(prefix, 'share')
destdir = environ.get('DESTDIR', '')

if not destdir:
    print('Updating icon cache...')
    icons_dir = path.join(datadir, 'icons', 'hicolor')
    call(['gtk-update-icon-cache', '-qtf', icons_dir])
    print("Installing new Schemas")
    schemas_dir =  path.join(datadir, 'glib-2.0/schemas')
    call(['glib-compile-schemas', schemas_dir])
    apps_dir =  path.join(datadir, 'applications')
    call(['update-desktop-database', apps_dir])
