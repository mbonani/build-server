#!/bin/sh

WORKSPACE=$1

cd "$WORKSPACE/source"
#TODO: make apt-get check signatures to get rid of --force-yes
mk-build-deps --install --tool "apt-get --no-install-recommends --assume-yes --force-yes" --remove
dpkg-buildpackage -us -uc