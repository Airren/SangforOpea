#!/usr/bin/env bash
# 进入下载目录
pushd ../kernel_deb || {
  echo "❌ kernel_deb is not exist"
  exit 1
}

# 定义安装顺序
components=(
  "linux-modules-6.8.0-49-generic_6.8.0-49.49~22.04.1_amd64.deb"
  "linux-modules-extra-6.8.0-49-generic_6.8.0-49.49~22.04.1_amd64.deb"
  "linux-image-6.8.0-49-generic_6.8.0-49.49~22.04.1_amd64.deb"
)

# 按顺序安装
for package_file in "${components[@]}"; do
  if [[ -n "$package_file" ]]; then
    echo "🔧 Install: $package_file"
    sudo dpkg -i "$package_file" || {
      echo "❌ Failed: $package_file"
      exit 1
    }
  else
    echo "⚠️ can not find ${package_file} deb package"
  fi
done

# 修复依赖
sudo apt-get -f install

popd || {
  echo "❌ exit failed"
  exit 1
}

echo "✅ New Kernel Installed Successful！"

sudo reboot
