[![Bountysource](https://img.shields.io/bountysource/team/jangernert-feedreader/activity.svg)](https://www.bountysource.com/teams/jangernert-feedreader/issues)


# [FeedReader](http://jangernert.github.io/FeedReader/)

[![Join the chat at https://gitter.im/Feedreader-dev/Lobby](https://badges.gitter.im/Feedreader-dev/Lobby.svg)](https://gitter.im/Feedreader-dev/Lobby?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

FeedReader is a modern desktop application designed to complement existing web-based RSS accounts. It combines all the advantages of web based services like synchronisation across all your devices with everything you expect from a modern desktop application.


<div style="text-align:center"><img src ="https://raw.githubusercontent.com/jangernert/feedreader/gh-pages/images/gallery/Screenshot4.png" /></div>

Website : http://jangernert.github.io/FeedReader/<br/>
For translators : https://www.transifex.com/dev-feedreader/feedreader



### Dependencies
- build-essential
- cmake
- vala (>=0.26)
- pkg-config
- libgirepository1.0-dev
- libgtk-3-dev (>= 3.22)
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


### How to install
  - Arch : <br/>
    <pre>
      yaourt -S feedreader
    </pre>
  - Fedora : <br/>
    <pre>
      sudo dnf install feedreader
    </per>
  - Solus OS : <br/>
    <pre>
      sudo eopkg install feedreader
    </pre>

### Flatpak

FeedReader is now availble as Flatpak and should be installable on all major Linux distributions that support the Flatpak Application Framework eg. Fedora, Debian, Ubuntu, elementaryOS, Arch, openSuSE, Mageia and many more.

For more information about Flatpak and how to use or install it for your distribution see the [Flatpak webpage](http://flatpak.org).

Besides installing the Flatpak Framework, you should also install the following portal packages using your distributions paket manager:
(names can differ depending on the distribution)
<pre>xdg-desktop-portal</pre>
<pre>xdg-desktop-portal-gtk</pre>

####Install FeedReader Flatpak via repository, this enables OTA updates and is the recommended way:
Defaults to the stable branch.
<pre>
flatpak install http://feedreader.xarbit.net/feedreader-repo/feedreader.flatpakref
</pre>

You can also create your own Flatpak bundle running `make bundle` command in the `flatpak/` sub-directory.


### How to build the latest version
```
git clone https://github.com/jangernert/FeedReader
cd ./FeedReader
mkdir build
cd ./build
cmake ..
make
sudo make install
```
Arch users can build the latest version using `yaourt -S feedreader-git`

