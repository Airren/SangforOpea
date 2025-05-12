#!/bin/bash
set -e

DEB_DIR="./xpu_debs"

# 安装顺序列表（不含版本）
debList=(
  "hwdata"
  "linux-tools-common"
  "libpython3.10"
  "libtraceevent1"
  "linux-hwe-6.8-tools-6.8.0-49"
  "linux-tools-6.8.0-49-generic"
  "intel-metrics-discovery"
  "libmetee"
  "intel-gsc"
  "intel-metrics-library"
  "libmfx1"
  "libmfx-tools"
  "xpu-smi"
)

# 遍历并安装
for base in "${debList[@]}"; do
    echo "==> Looking for package: $base"

    matches=( $(find "$DEB_DIR" -maxdepth 1 -type f -name "${base}_*.deb") )

    if [ "${#matches[@]}" -eq 0 ]; then
        echo "ERROR: No .deb file found for package base name: $base"
        exit 1
    elif [ "${#matches[@]}" -gt 1 ]; then
        echo "ERROR: Multiple .deb files found for '$base':"
        printf "  %s\n" "${matches[@]}"
        exit 1
    fi

    pkg="${matches[0]}"
    echo "Installing $pkg ..."
    sudo apt install "$pkg" 
    echo "Installed: $pkg"
done

echo "✅ All specified packages installed successfully."

