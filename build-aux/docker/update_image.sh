#!/bin/bash -e
NAME=docker.io/feedreader/fedora-feedreader-devel

sudo docker build . -t "$NAME"
sudo docker push "$NAME"
