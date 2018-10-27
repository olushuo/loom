
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

