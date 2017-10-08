# Dependencies

Package names may differ depending on distribution

- build-essential
- meson
- vala (>=0.26)
- pkg-config
- libgirepository1.0-dev
- libgtk-3-dev (>= 3.20)
- libsoup2.4-dev
- libjson-glib-dev
- libwebkit2gtk-4.0-dev
- libsqlite3-dev
- libsecret-1-dev
- libnotify-dev
- libxml2-dev
- libunity-dev (optional)
- librest-dev
- libgee-0.8-dev
- libgstreamer1.0-dev
- libgstreamer-plugins-base1.0-dev (gstreamer-pbutils-1.0)
- libgoa-1.0-dev (>= 3.20)
- libcurl-dev
- libpeas-dev

## Fedora dependencies installation

```shell
dnf install gtk3-devel gtk2-devel vala gcc gcc-c++ meson json-glib-devel libsoup-devel sqlite-devel libgee-devel libsecret-devel libxml-devel rest-devel gstreamer1-devel gstreamer1-plugins-base-devel libpeas-devel webkitgtk4-devel gnome-online-accounts-devel libcurl-devel
```

# Compiling

```shell
git clone --recursive  https://github.com/jangernert/FeedReader
cd ./FeedReader
meson builddir
sudo ninja -C builddir install
```
