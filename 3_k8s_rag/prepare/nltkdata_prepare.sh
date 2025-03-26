#!/usr/bin/env bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
# nltk_data path
set -ex
data_path=`readlink -f "${SCRIPT_DIR}/../../nltk_data"`
mkdir -p "$data_path"

rm -rf nltk_venv
virtualenv -p python3 nltk_venv
source nltk_venv/bin/activate
pip install nltk

python -m nltk.downloader -d "${data_path}" all

echo "✅ all nltk data are downloaded"

rm -rf nltk_venv
