#!/bin/bash

# 进入下载目录
pushd ../docker_deb || {
  echo "❌ docker deb is not exist"
  exit 1
}

# 定义安装顺序
components=(
  "containerd.io"
  "docker-ce-cli"
  "docker-ce"
  "docker-buildx-plugin"
  "docker-compose-plugin"
)

# 按顺序安装
for component in "${components[@]}"; do
  package_file=$(ls | grep "^${component}_.*_amd64.deb$")
  if [[ -n "$package_file" ]]; then
    echo "🔧 Install: $package_file"
    sudo dpkg -i "$package_file" || {
      echo "❌ Failed: $package_file"
      exit 1
    }
  else
    echo "⚠️ can not fine ${component} deb package"
  fi
done

# 修复依赖
sudo apt-get -f install

popd || {
  echo "❌ exit failed"
  exit 1
}

echo "✅ Docker Install Successful！"

sudo groupadd docker
sudo usermod -aG docker $USER

