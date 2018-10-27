
#!/bin/bash

source $(dirname ${BASH_SOURCE})/trace.sh || die "Failed to find trace.sh"
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
    note "JDK $1 will be installed"
fi

VERSION=$1

JDK_PACKAGE=jdk-${VERSION}_linux-x64_bin.tar.gz
JDK_URL=http://download.oracle.com/otn-pub/java/jdk/${VERSION}+13/90cf5d8f270a4347a95050320eef3fb7/${JDK_PACKAGE}

sudo rm -rf ${JDK_PACKAGE}
wget --no-cookies \
    --header "Cookie: oraclelicense=accept-securebackup-cookie" \
    ${JDK_URL} \
    -O /tmp/${JDK_PACKAGE}

sudo rm -rf /opt/java/${VERSION}
sudo mkdir -p /opt/java/${VERSION}/

sudo tar -C /opt/java/${VERSION}/ -xzf /tmp/${JDK_PACKAGE}

sudo rm -rf ${JDK_PACKAGE}

JDK_PLUGIN="${HOME}/.oh-my-zsh/custom/JAVA_plugin.zsh"
rm -f ${JDK_PLUGIN}

echo "export JAVA_VERSION=${VERSION}" > ${JDK_PLUGIN}
echo 'export JAVA_HOME=/opt/java/${JAVA_VERSION}/jdk-${JAVA_VERSION}' >> ${JDK_PLUGIN}
echo 'export PATH=${JAVA_HOME}/bin:${PATH}' >> ${JDK_PLUGIN}

