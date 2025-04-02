
# Intel Arc GPU 系统安装

## BIOS 设置

Intel Arc GPU要求配置BIOS打开`PCIe resizable BAR`的支持.

## 选项1: 在线安装操作系统和GPU驱动

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

## 选项2: 离线安装操作系统和GPU驱动



## 选项3: 使用Clonezilla恢复硬盘镜像

使用[Clonezilla](https://clonezilla.org/)工具可以快速的制作或者恢复硬盘镜像,适用于离线环境下快速安装符合目标环境的操作系统.

本示例演示了使用[Clonezilla live](https://clonezilla.org/clonezilla-live.php)来恢复硬盘镜像的过程.

### 步骤1: 制作Clonezilla live 启动U盘

1. 从Clonezilla官方网站上下载[Clonezilla live zip文件](https://clonezilla.org/liveusb.php), `clonezilla-live-20250303-oracular-amd64.zip`.

2. 给启动U盘分区并格式化

   2.1 在Linux系统上插入新的U盘（至少需要500MB以上空间）, 假设此U盘设备为`/dev/sdb`.

   2.2 给U盘分区并格式化

   ```bash
   sudo parted /dev/sdb mklabel gpt
   sudo parted /dev/sdb mkpart ESP fat32 1MiB 100%
   sudo parted /dev/sdb set 1 boot on
   sudo parted /dev/sdb print
   sudo mkfs.vfat /dev/sdb1
   ```

   2.3 拷贝CloneZilla live到启动U盘

   ```bash
   sudo mkdir -p /mnt/media
   sudo mount /dev/sdb1 /mnt/media
   sudo unzip clonezilla-live-20250303-oracular-amd64.zip -d /mnt/media
   sudo umount /mnt/media
   ```

### 步骤2: 制作CloneZilla OS镜像数据U盘

1. 获取OS镜像数据文件

|   文件名称                   | 包含内容                  | U盘大小要求 |
|-----------------------------|-------------------------|------------|
| ubuntu-22.04.1-a770-img.tar | 操作系统，Arc GPU 驱动    | 4GB        |
| sangfor-0403-ubuntu-22.04-opea.tar | 操作系统, Arc GPU驱动，OPEA chatqna离线运行环境 | 240GB |

2. 选择一个镜像文件，拷贝数据到数据U盘(假设U盘设备为`/dev/sdd1`)，例如：

```bash
sudo mount /dev/sdd1 /mnt/media
sudo tar Cxf /mnt/meida ubuntu-22.04.1-a770-img.tar 
sudo umount /mnt/media
```

### 步骤3:恢复操作系统镜像

在需要安装的机器上，使用`步骤1`中制作的Clonezilla live启动U盘，启动Clonezilla live，并按照[CloneZilla官方教程中的恢复步骤](https://clonezilla.org/fine-print-live-doc.php?path=clonezilla-live/doc/02_Restore_disk_image)，使用`步骤2`中制作的数据U盘，恢复操作系统镜像。

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
