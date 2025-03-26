
# Intel Arc GPU 系统安装

## BIOS 设置

Intel Arc GPU要求配置BIOS打开`PCIe resizable BAR`的支持.

## 安装操作系统和GPU驱动

为了发挥Intel Arc GPU的最大性能，推荐安装如下版本的操作系统，内核，以及GPU驱动：

- 操作系统: [Ubuntu 22.04.1](https://old-releases.ubuntu.com/releases/22.04.1/ubuntu-22.04.1-desktop-amd64.iso)

- 内核: 6.8.0-49-generic

- GPU驱动: 请使用如下指令安装GPU驱动

```bash
# Add Intel GPU out of tree driver repository
wget -qO - https://repositories.intel.com/gpu/intel-graphics.key | sudo gpg --yes --dearmor --output /usr/share/keyrings/intel-graphics.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/intel-graphics.gpg] https://repositories.intel.com/gpu/ubuntu jammy/lts/2350 unified" | sudo tee /etc/apt/sources.list.d/intel-gpu-jammy.list
sudo apt update

# Install compute, media, display runtime
sudo apt install -y \
  intel-opencl-icd intel-level-zero-gpu level-zero \
  intel-media-va-driver-non-free libmfx1 libmfxgen1 libvpl2 \
  libegl-mesa0 libegl1-mesa libegl1-mesa-dev libgbm1 libgl1-mesa-dev libgl1-mesa-dri \
  libglapi-mesa libgles2-mesa-dev libglx-mesa0 libigdgmm12 libxatracker2 mesa-va-drivers \
  mesa-vdpau-drivers mesa-vulkan-drivers va-driver-all vainfo hwinfo clinfo

# Install Development Packages
sudo apt install -y libigc-dev intel-igc-cm libigdfcl-dev libigfxcmrt-dev level-zero-dev

# Install dkms and Kernel Header Files
sudo apt -y install gawk dkms linux-headers-$(uname -r) libc6-dev

# Install out of tree GPU  driver
sudo apt install -y intel-i915-dkms intel-fw-gpu
sudo reboot -h now

# Configuring Render Group Membership 
# find the render group 
stat -c "%G" /dev/dri/render*
# add current user to the render group
sudo gpasswd -a ${USER} render
newgrp render
```

## 验证GPU驱动是否正常工作

1. 确保系统启动时，i915驱动没有报错: `sudo dmesg | grep -i 915`

2. 确认INTEL_VSEC 功能已被开启: `sudo modinfo i915 | more`，例如:
   ```
   llm@Xeon-xxx-A770:~$ sudo modinfo i915 | more
   filename: /lib/modules/6.8.0-49-generic/updates/dkms/i915.ko
   license: GPL and additional rights
   description: Intel Graphics
   version: backported to 6.8.0-49 from (8d397bfd8898f) using backports
   I915_23.10.83_PSB_231129.89
   author: Intel Corporation
   author: Tungsten Graphics, Inc.
   import_ns: INTEL_VSEC
   import_ns: DMA_BUF
   ```

3. 确认i915驱动被正常加载: `sudo hwinfo --display`, 例如
   ```
   llm@Xeon-xxx-A770:~$ sudo hwinfo --display
   Driver Info #0:
   Driver Status: xe is active
   Driver Activation Cmd: "modprobe xe"
   Driver Info #1:
   Driver Status: i915 is active
   Driver Activation Cmd: "modprobe i915"
   Config Status: cfg=new, avail=yes, need=no, active=unknown
   ```

4. 确保Arc 770 PCIe configuration有16GB的空间

   首先找到Arc 770的PCI设备地址`lspci | grep -i vga`

   可能的输出如下：
   ```
   llm@Xeon-xxx-A770:~$ lspci |grep -i vga
   19:00.0 VGA compatible controller: Intel Corporation Device 56a0 (rev 08)
   2c:00.0 VGA compatible controller: Intel Corporation Device 56a0 (rev 08)
   52:00.0 VGA compatible controller: Intel Corporation Device 56a0 (rev 08)
   65:00.0 VGA compatible controller: Intel Corporation Device 56a0 (rev 08)
   ```

   运行`sudo lspci -s <pci设备地址> -vvvv | grep Resizable -C 5`确认PCIe configuration的BAR空间是否是16GB.