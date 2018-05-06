[![Translation status](https://hosted.weblate.org/widgets/feedreader/-/svg-badge.svg)](https://hosted.weblate.org/engage/feedreader/?utm_source=widget) [![CircleCI](https://circleci.com/gh/jangernert/FeedReader.svg?style=shield)](https://circleci.com/gh/jangernert/FeedReader) [![Bountysource](https://img.shields.io/bountysource/team/jangernert-feedreader/activity.svg)](https://www.bountysource.com/teams/jangernert-feedreader/issues) [![Join the chat at https://gitter.im/Feedreader-dev/Lobby](https://badges.gitter.im/Feedreader-dev/Lobby.svg)](https://gitter.im/Feedreader-dev/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)


# [FeedReader](http://jangernert.github.io/FeedReader/)

FeedReader is a modern desktop application designed to complement existing web-based RSS accounts. It combines all the advantages of web based services like synchronisation across all your devices with everything you expect from a modern desktop application.


<div style="text-align:center"><img src ="https://raw.githubusercontent.com/jangernert/feedreader/gh-pages/images/gallery/Screenshot4.png" /></div>

Website : http://jangernert.github.io/FeedReader/<br/>
For translators : https://hosted.weblate.org/projects/feedreader/



## Dependencies
- `build-essential`
- `meson`
- `ninja-build`
- `vala (>=0.38)`
- `pkg-config`
- `libgirepository1.0-dev`
- `libgtk-3-dev (>= 3.22)`
- `libsoup2.4-dev`
- `libjson-glib-dev`
- `libwebkit2gtk-4.0-dev (>=2.18)`
- `libsqlite3-dev`
- `libsecret-1-dev`
- `libnotify-dev`
- `libxml2-dev`
- `libunity-dev (optional)`
- `librest-dev`
- `libgee-0.8-dev`
- `libgstreamer1.0-dev`
- `libgstreamer-plugins-base1.0-dev (gstreamer-pbutils-1.0)`
- `libgoa-1.0-dev (>= 3.20)`
- `libcurl-dev`
- `libpeas-dev`


## How to install
### Arch Linux : <br/>
```bash
yaourt -S feedreader
```
### Fedora : <br/>
```bash
sudo dnf install feedreader
```
### Solus OS : <br/>
```bash
sudo eopkg install feedreader
```

### openSUSE : <br/>
```bash
sudo zypper install feedreader
```

### Ubuntu : <br/>

The easiest way to install the latest FeedReader right now is to build from source,
which you can do with this script:

```bash
curl https://raw.githubusercontent.com/jangernert/FeedReader/master/scripts/install_ubuntu.sh | bash
```

### Flatpak

FeedReader is now availble as Flatpak and should be installable on all major Linux distributions that support the Flatpak Application Framework eg. Fedora, Debian, Ubuntu, elementaryOS, Arch, openSuSE, Mageia and many more.

For more information about Flatpak and how to use or install it for your distribution see the [Flatpak webpage](http://flatpak.org).

Besides installing the Flatpak Framework, you should also install the following portal packages using your distributions package manager:
- `xdg-desktop-portal`
- `xdg-desktop-portal-gtk`

#### Via repository
This enables OTA updates and is the recommended way. Defaults to the stable branch.
<pre>
flatpak install http://feedreader.xarbit.net/feedreader-repo/feedreader.flatpakref
</pre>

You can also create your own Flatpak bundle running `make bundle` command in the `flatpak/` sub-directory.


### Manual installation
```
git clone --recursive https://github.com/jangernert/FeedReader
cd ./FeedReader
meson builddir --prefix=/usr
sudo ninja -C builddir install
```
Arch Linux users can build the latest version using `yaourt -S feedreader-git`
