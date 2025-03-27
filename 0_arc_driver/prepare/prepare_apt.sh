#!/usr/bin/env bash
ubuntu_codename=$(lsb_release -sc)
function build_repo() {
  # 设置默认的 APT 缓存目录
  local apt_cache_dir=${1:-/home/airren/NFSShared/apt_deb}
  local build_dir=${2:-/localrepo}

  # 将 apt_cache_dir 转换为绝对路径
  if [[ ! "$apt_cache_dir" = /* ]]; then
    apt_cache_dir="$(realpath "$apt_cache_dir")"
  fi

  # 将 build_dir 转换为绝对路径
  if [[ ! "$build_dir" = /* ]]; then
    build_dir="$(realpath "$build_dir")"
  fi

  sudo mkdir -p ${build_dir}
  sudo chown -R $USER:$USER "${build_dir}"

  # 创建必要的目录结构
  mkdir -p "${build_dir}/dists/${ubuntu_codename}/main/binary-amd64/"
  mkdir -p "${build_dir}/pool/main/"

  # 复制 .deb 文件到 pool/main/
  sudo cp "${apt_cache_dir}"/*.deb "${build_dir}/pool/main/"

  # 自动生成 override-file
  local override_file="${build_dir}/override-file"
  echo -n | tee "${override_file}" # 清空或创建 override-file
  local package_list_file="packages_${system_name}${system_version}.txt"
  echo -n >"${package_list_file}" # 清空或创建 package list 文件

  for deb_file in "${build_dir}/pool/main/"*.deb; do
    if [ -f "${deb_file}" ]; then
      # 提取包名和版本号
      package_info=$(sudo dpkg-deb --show "${deb_file}")
      package_name=$(echo "${package_info}" | awk '{print $1}')
      package_version=$(echo "${package_info}" | awk '{print $2}')

      # 写入 override-file
      echo "${package_name} optional misc" | sudo tee -a "${override_file}"

      # 写入 package list 文件
      echo "${package_name}=${package_version}" >>"${package_list_file}"
    fi
  done

  # 生成 Packages.gz 和 Packages 文件
  pushd ${build_dir} >/dev/null
  sudo dpkg-scanpackages "pool/main" "${override_file}" | gzip -9c >"dists/${ubuntu_codename}/main/binary-amd64/Packages.gz"
  sudo gunzip -c "dists/${ubuntu_codename}/main/binary-amd64/Packages.gz" >"dists/${ubuntu_codename}/main/binary-amd64/Packages"
  popd >/dev/null

  # 生成 Release 文件
  sudo apt-ftparchive release "${build_dir}/dists/${ubuntu_codename}/" >"${build_dir}/dists/${ubuntu_codename}/Release"

  # 添加自定义信息到 Release 文件
  cat <<EOF | sudo tee -a "${build_dir}/dists/${ubuntu_codename}/Release"
Origin: Local-APT-Repo
Label: Local Repository
Codename: ${ubuntu_codename}
Architectures: amd64
Components: main
Description: Custom offline APT repository
EOF

  # 设置权限
  sudo chown -R _apt:root "${build_dir}"
  sudo mv "${build_dir}" offline-apt

  # 输出生成的 package list 文件路径
  echo "Generated package list: ${package_list_file}"
}

build_repo /home/airren/NFSShared/apt_deb /localrepo
