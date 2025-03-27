#!/usr/bin/env bash

# Install Compute, Media, and Display Runtimes
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

# Install the Out-of-Tree Kernel Driver
sudo apt install -y intel-i915-dkms intel-fw-gpu

sudo reboot -h now
