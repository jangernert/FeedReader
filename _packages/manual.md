---
distro: Manual Installation
data-content: source
---

#### Required dependencies:

The packages names can differ depending on the distribution
```
build-essential
meson
ninja-build
vala (>=0.26)
pkg-config
libgirepository1.0-dev
libgtk-3-dev (>= 3.22)
libsoup2.4-dev
libjson-glib-dev
libwebkit2gtk-4.0-dev (or 3.0
libsqlite3-dev
libsecret-1-dev
libnotify-dev
libxml2-dev
libunity-dev (optional)
librest-dev
libgee-0.8-dev
libgstreamer1.0-dev
libgstreamer-plugins-base1.0-dev (gstreamer-pbutils-1.0)
libgoa-1.0-dev (>= 3.20)
libcurl-dev
libpeas-dev
```


1 - Navigate to the directory which contains the source and run meson to generate the required build-files:
```
meson -C builddir --prefix=/usr
```
2 - Compile the source-code and install the binaries:
```
sudo ninja -C builddir install
```