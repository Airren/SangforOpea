# Ubuntu 22.04 Kernel 升级与 Arc GPU 驱动安装

> [!IMPORTANT]
> 为了保证Arc GPU可以发挥最佳性能，请严格按照文档说明准备安装部署环境。
> 

[TOC]

## 0. 服务器硬件要求以及BIOS设置

- **CPU**: Xeon 4th/5th CPU
- **BIOS**: 启用 `Resizable BAR` 功能

---

> 请根据实际的网络情况选择安装方式，离线状态下可以选择 `选项1`，`选项3`.

## 选项1:  使用Intel提供的安装包升级Kernel以及Driver安装(离线场景)

### 1. 操作系统准备

安装操作系统：Ubuntu 22.04.1 (x86_64)。

> **注意：** 请确保下载并使用 `22.04.1` 版本。

```bash
wget https://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.1-live-server-amd64.iso
```

### 2. 内核升级

将 Ubuntu 22.04.1 的内核升级至 `6.8.0-49-generic`，可按照以下步骤进行：

运行以下命令安装内核并自动重启。
> **提示：** 脚本中已包含重启命令，若需手动重启，请注释相关行。
> 
> 内核安装完成之后，请进一步检查grub的配置文件，确保默认启动内核版本为6.8.0-49-generic。

```bash
cd 0_arc_driver
bash ./install_kernel.sh
```

### 3. Arc GPU 驱动安装
重启完成后，请检查当前内核版本是否为 `6.8.0-49-generic`。
```bash
uname -r
```

## 3. Arc GPU 驱动安装

#### 3.1 加载离线 APT 源

```bash
cd 0_arc_driver
bash ./prepare_apt.sh
```

#### 3.2 安装 Arc GPU 驱动并重启

> **提示：** 脚本中已包含重启命令，若需手动重启，请注释相关行。

```bash
bash ./install_arc_driver.sh
```

---

## 选项2: 在线Kernel升级以及Arc GPU Driver安装(在线场景)

### 1. 操作系统准备

安装操作系统：Ubuntu 22.04.1 (x86_64)。

> **注意：** 请确保下载并使用 `22.04.1` 版本。

```bash
wget https://old-releases.ubuntu.com/releases/jammy/ubuntu-22.04.1-live-server-amd64.iso
```

### 2.升级内核并重启

将 Ubuntu 22.04.1 的内核升级至 `6.8.0-49-generic`，可按照以下步骤进行：

```shell

sudo apt install -y linux-image-6.8.0-49-generic linux-modules-6.8.0-49-generic linux-modules-extra-6.8.0-49-generic

```

内核安装完成之后，请进一步检查grub的配置文件，确保默认启动内核版本为6.8.0-49-generic。

```bash
sudo reboot
```

重启完成后，请检查当前内核版本是否为 `6.8.0-49-generic`。
```bash
uname -r
```


### 3.Arc GPU驱动安装

请使用如下指令安装GPU驱动

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


---

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


---

## Arc GPU驱动验证

验证GPU驱动是否正常工作

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
