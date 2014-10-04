#!/bin/bash -x
set -e
VERSION=`cat VERSION`

./make-tarball.sh

# deb package
rm -rf _build/deb
mkdir -p _build/deb/
cp _build/ma-agent-${VERSION}.tar.gz _build/deb/ma-agent_${VERSION}.orig.tar.gz
pushd _build/deb/ && tar -xf ma-agent_${VERSION}.orig.tar.gz 
popd
cp -r deb/ _build/deb/ma-agent-${VERSION}/debian/
pushd _build/deb/ma-agent-${VERSION} && dpkg-buildpackage -us -uc 
