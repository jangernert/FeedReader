[![Translation status](https://hosted.weblate.org/widgets/feedreader/-/svg-badge.svg)](https://hosted.weblate.org/engage/feedreader/?utm_source=widget) [![CircleCI](https://circleci.com/gh/jangernert/FeedReader.svg?style=shield)](https://circleci.com/gh/jangernert/FeedReader) [![Bountysource](https://img.shields.io/bountysource/team/jangernert-feedreader/activity.svg)](https://www.bountysource.com/teams/jangernert-feedreader/issues) [![Join the chat at https://gitter.im/Feedreader-dev/Lobby](https://badges.gitter.im/Feedreader-dev/Lobby.svg)](https://gitter.im/Feedreader-dev/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<a href="https://flathub.org/apps/details/org.gnome.FeedReader"><img src="https://flathub.org/assets/badges/flathub-badge-i-en.png" alt="Download on Flathub" width="190px"></a>


# [FeedReader](http://jangernert.github.io/FeedReader/)

FeedReader is a modern desktop application designed to complement existing web-based RSS accounts. It combines all the advantages of web based services like synchronisation across all your devices with everything you expect from a modern desktop application.


<div style="text-align:center"><img src ="https://raw.githubusercontent.com/jangernert/feedreader/gh-pages/images/gallery/Screenshot4.png" /></div>

Website : http://jangernert.github.io/FeedReader/<br/>
For translators : https://hosted.weblate.org/projects/feedreader/

## Build from source

These are the instructions for building and testing locally. We generally
recommend that you use the Flatpak build whenever possible though.

### Ubuntu

Install dependencies:

```
sudo apt-get install \
	build-essential \
	meson \
	ninja-build \
	vala \
	pkg-config \
	libgirepository1.0-dev \
	libgtk-3-dev \
	libgumbo-dev \
	libsoup2.4-dev \
	libjson-glib-dev \
	libwebkit2gtk-4.0-dev \
	libsqlite3-dev \
	libsecret-1-dev \
	libnotify-dev \
	libxml2-dev \
	libunity-dev \
	librest-dev \
	libgee-0.8-dev \
	libgstreamer1.0-dev \
	libgstreamer-plugins-base1.0-dev \
	libgoa-1.0-dev \
	libcurl-dev \
	libpeas-dev
```

### Fedora

Install dependencies:

```
RUN dnf install \
	gcc \
	gettext \
	git \
	gnome-online-accounts-devel \
	gstreamer1-devel \
	gstreamer1-plugins-base-devel \
	gtk3-devel \
	gumbo-parser-devel \
	json-glib-devel \
	libcurl-devel \
	libgee-devel \
	libnotify-devel \
	libpeas-devel \
	libsecret-devel \
	libsoup-devel \
	libxml2-devel \
	meson \
	rest-devel \
	sqlite-devel \
	vala \
	webkitgtk4-devel \
	appstream \
	desktop-file-utils \
	libunity-devel
```

### Build

```
git clone --recursive https://github.com/jangernert/FeedReader
cd ./FeedReader
meson builddir --prefix=/usr
ninja -C builddir install
# Now run `feedreader`
```
