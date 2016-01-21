[![Bountysource](https://www.bountysource.com/badge/tracker?tracker_id=16778038)](https://www.bountysource.com/teams/feedreader-gtk/issues?tracker_ids=16778038)


# FeedReader

FeedReader is a modern desktop application designed to complement existing web-based RSS accounts. It combines all the advantages of web based services like synchronisation across all your devices with everything you expect from a modern desktop application.


### Dependencies 
- build-essential
- cmake
- valac
- libgirepository1.0-dev
- libgtk-3-dev
- libsoup2.4-dev
- libjson-glib-dev
- libwebkit2gtk-3.0-dev (or version 4.0 with build switch -DUSE_WEBKIT_4=ON)
- libsqlite3-dev
- libsecret-1-dev
- libnotify-dev
- libxml2-dev
- libunity-dev (optional: disable with -DWITH_LIBUNITY=OFF)
- librest-dev
- libgee-0.8-dev


### How to install 
  - Elementary OS / Ubuntu / Debian:<br/>
    <pre>
    sudo add-apt-repository ppa:eviltwin1/feedreader-stable
    sudo apt-get update
    sudo apt-get install feedreader
    </pre>
  - Arch : <br/>
    <pre>
      yaourt feedreader
    </pre>
  - Fedora : <br/>
    <pre>
      sudo dnf install feedreader
    </per>
  - Solus OS  <br/>
    <pre>
      sudo eopkg install feedreader
    </pre>
    
### How to build the latest version
```
git clone https://github.com/jangernert/FeedReader && cd ./FeedReader
mkdir build & cd ./build 
cmake -DCMAKE_INSTALL_PREFIX=/usr ..
make -j 1
sudo make install
```
