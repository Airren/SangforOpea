#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
BASEDIR="${SCRIPT_DIR}/.."


TARGETDIR=${OPEA_DATA_DIR:-/opt/opea-offline-data}


function populate_data() {
    basedir=$1
    targetdir=$2

    sudo mkdir -p $targetdir
    sudo chmod a+w $targetdir
    rsync -av $basedir $targetdir
    sudo chmod -R a+r $targetdir
}


set -ex
populate_data ${BASEDIR}/models $TARGETDIR
populate_data ${BASEDIR}/nltk_data $TARGETDIR
set +ex