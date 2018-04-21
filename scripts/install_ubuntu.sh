#!/bin/bash
sudo add-apt-repository ppa:vala-team
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install build-essential cmake valac pkg-config libgirepository1.0-dev libgtk-3-dev libsoup2.4-dev libjson-glib-dev libwebkit2gtk-4.0-dev libsqlite3-dev libsecret-1-dev libnotify-dev libxml2-dev librest-dev libgee-0.8-dev libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev libgoa-1.0-dev libcurl4-gnutls-dev libpeas-dev
cd /tmp/
git clone --recursive https://github.com/jangernert/FeedReader
cd ./FeedReader
mkdir build
cd ./build
cmake ..
make
sudo make install
sudo rm -r /tmp/FeedReader
