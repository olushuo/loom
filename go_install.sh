#!/bin/bash

source $(dirname ${BASH_SOURCE})/trace.sh || die "Failed to find trace.sh"
source $(dirname ${BASH_SOURCE})/utils.sh || die "Failed to find utils.sh"

function usage() {
    echo "${0##*/} usage:"
    echo "  ${0##*/} <version_number>"
}

if [[ $# != 1 ]] ; then
    usage
    exit 1
elif [[ $# == 1 && $1 == "-h" ]] ; then
    usage
    exit 0
elif [[ $# == 1 ]] ; then
    note "Go language $1 will be installed"
fi

VERSION=$1
GOLANG_PACKAGE=go${VERSION}.linux-amd64.tar.gz

sudo rm -rf ${GOLANG_PACKAGE}
wget https://dl.google.com/go/${GOLANG_PACKAGE} \
    -O /tmp/${GOLANG_PACKAGE}

sudo rm -rf /opt/go/${VERSION}
sudo mkdir -p /opt/go/${VERSION} 

sudo tar -C /opt/go/${VERSION} -xzf /tmp/${GOLANG_PACKAGE}

sudo rm -rf ${GOLANG_PACKAGE}

GOLANG_PLUGIN="${HOME}/.oh-my-zsh/custom/golang_plugin.zsh"
rm -f ${GOLANG_PLUGIN}
echo "export GOVERSION=${VERSION}" > ${GOLANG_PLUGIN}
echo 'export GOROOT=/opt/go/${GOVERSION}/go' >> ${GOLANG_PLUGIN}
echo 'export GOPATH=/${HOME}/gobin' >> ${GOLANG_PLUGIN}
echo 'export PATH=${PATH}:${GOROOT}/bin:${GOPATH}/bin' >> ${GOLANG_PLUGIN}

