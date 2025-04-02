#!/usr/bin/env bash
sudo mkdir -p /local_apt_repo
sudo chmod a+w /local_apt_repo
rsync -av ../apt_packages /local_apt_repo
sudo tee /etc/apt/sources.list.d/local-repo.list <<EOF
deb [trusted=yes] file:///local_apt_repo/apt_packages $(lsb_release -sc) main
EOF

sudo apt update -o Dir::Etc::sourcelist=/etc/apt/sources.list.d/local-repo.list