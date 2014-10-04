VERSION=1.0.0
ROOT=_build/ma-agent-${VERSION}
OPT_ROOT=${ROOT}/opt/ma-agent

all: 
	echo "please give task name: npm, rpm... etc"
	echo ${ARCH}
	echo ${JRE}

_build:
	mkdir _build
	mkdir -p _build/tar
	mkdir -p _build/npm/lib
	mkdir -p _build/rpmbuild/SPECS
	mkdir -p _build/rpmbuild/SOURCES
	mkdir -p _build/rpmbuild/RPMS
	mkdir -p _build/rpmbuild/SRPMS
	mkdir -p _build/rpmbuild/BUILD
	mkdir -p _build/rpmbuild/BUILDROOT
	mkdir -p ${OPT_ROOT}

npm: _build compile_coffee
	cp index.js ./_build/npm
	cp ./package.json ./_build/npm

compile_coffee:
	coffee -c -o _build/npm/lib ./src/node

_build/ma-agent.jar: 
	ant

install: rpm
	sudo rpm -ihv _build/rpmbuild/RPMS/x86_64/ma-agent-${VERSION}-1.x86_64.rpm

rsync_dev:
	rsync -avz ./_build/rpmbuild/RPMS/x86_64/ma-agent-1.0.0-1.x86_64.rpm  mingqi@dev.monitorat.com:/var/tmp/

clean:
	rm -rf ./_build

linstall: _build/ma-agent.jar lib npm luninstall
	cp bin/* /opt/ma-agent/bin/ 
	cp _build/ma-agent.jar /opt/ma-agent/lib
	cp lib/*.jar /opt/ma-agent/lib
	cp -r _build/npm/lib/ /opt/ma-agent/node_modules/ma-agent/lib
	cp -r node_modules/ /opt/ma-agent/node_modules/ma-agent/node_modules
	# cp conf/dev.conf /etc/ma-agent/ma-agent.conf

luninstall:
	rm -rf /opt/ma-agent/bin/*
	rm -rf /opt/ma-agent/lib/*
	rm -rf /opt/ma-agent/node_modules/ma-agent/*
