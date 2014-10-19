#!/bin/bash -x
set -e
VERSION=`cat VERSION`

./make-tarball.sh

# deb package
rm -rf _build/deb
mkdir -p _build/deb/
cp _build/uc-agent-${VERSION}.tar.gz _build/deb/uc-agent_${VERSION}.orig.tar.gz
pushd _build/deb/ && tar -xf uc-agent_${VERSION}.orig.tar.gz 
popd
cp -r deb/ _build/deb/uc-agent-${VERSION}/debian/
pushd _build/deb/uc-agent-${VERSION} && dpkg-buildpackage -us -uc 
