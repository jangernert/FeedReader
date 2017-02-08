[![Bountysource](https://img.shields.io/bountysource/team/jangernert-feedreader/activity.svg)](https://www.bountysource.com/teams/jangernert-feedreader/issues)


# [FeedReader](http://jangernert.github.io/FeedReader/)

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


### How to install
  - elementary OS / Ubuntu :<br/>
    <pre>
    sudo add-apt-repository ppa:eviltwin1/feedreader-stable
    sudo apt-get update
    sudo apt-get install feedreader
    </pre>
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
  - openSUSE Tumbleweed : <br/>
    <pre>
      sudo zypper addrepo http://download.opensuse.org/repositories/home:scujas:feedreader/openSUSE_Tumbleweed/home:scujas:feedreader.repo
      sudo zypper refresh
      sudo zypper install feedreader
    </pre>
  - openSUSE using 1-Click-Install
   - [openSUSE Tumbleweed](http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Tumbleweed/feedreader.ymp)
   - [openSUSE Leap 42.1](http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Leap_42.1/feedreader.ymp)
   - [openSUSE Leap 42.2](http://software.opensuse.org/ymp/home:scujas:feedreader/openSUSE_Leap_42.2/feedreader.ymp)

#### Flatpak Bundle (testing) 

FeedReader is now availble as a standalone Flatpak file and should be installable on all Linux distributions that support the Flatpak Application Framework. This is still a WIP and might not work as expected, please report any Flatpak related issues [HERE](https://github.com/jscurtu/feedreader-flatpak/issues). 

For more information about Flatpak and how to use or install it for your distribution see the [Flatpak webpage](http://flatpak.org).

For FeedReader to properly work, you will also need to install the following portal packages, look in your distributions packagemanager:

- xdg-desktop-portal 
- xdg-desktop-portal-gtk

When all set, download the flatpak'd standalone bundle here:

- [FeedReader 1.6.2 Flatpak](https://github.com/jscurtu/feedreader-flatpak/releases)

GNOME-Software can handle flatpak bundles, just open the downloaded feedreader.flatpak file with GNOME-Software and click on install. Thats it..

You can also install the feedreader.flatpak from the commandline as so:

<pre>
	$ flatpak install --bundle feedreader.flatpak
</pre>


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
You can also create a Flatpak bundle using `./build_flatpak.sh`
