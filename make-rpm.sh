#!/bin/bash
VERSION=`cat VERSION`

set -e

## tarball
./make-tarball.sh $@

## rpmbuild
mv _build/uc-agent-${VERSION}.tar.gz _build/rpmbuild/SOURCES
cp redhat/uc-agent.spec _build/rpmbuild/SPECS
cp redhat/uc-agent.init _build/rpmbuild/SOURCES

cd _build/rpmbuild && rpmbuild -ba SPECS/uc-agent.spec
