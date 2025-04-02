# Function to download packages from packages.txt
sudo apt install --reinstall --download-only \
  linux-image-6.8.0-49-generic \
  linux-modules-6.8.0-49-generic \
  linux-modules-extra-6.8.0-49-generic

sudo apt install --reinstall --download-only \
  clinfo hwinfo i965-va-driver intel-igc-cm intel-level-zero-gpu \
  intel-media-va-driver-non-free intel-opencl-icd level-zero libdrm-amdgpu1 \
  libdrm-intel1 libdrm-nouveau2 libdrm-radeon1 libegl-dev libegl-mesa0 libegl1 \
  libegl1-mesa libegl1-mesa-dev libgbm1 libgl-dev libgl1 libgl1-mesa-dev \
  libgl1-mesa-dri libglapi-mesa libgles-dev libgles1 libgles2 libgles2-mesa-dev \
  libglvnd-core-dev libglvnd-dev libglvnd0 libglx-dev libglx-mesa0 libglx0 \
  libhd21 libigc1 libigdfcl1 libigdgmm12 libllvm15 libmfx1 libmfxgen1 \
  libnl-route-3-200 libopengl-dev libopengl0 libpciaccess0 libpthread-stubs0-dev \
  libsensors-config libsensors5 libva-drm2 libva-wayland2 libva-x11-2 libva2 \
  libvdpau1 libvpl2 libvulkan1 libwayland-client0 libwayland-server0 libx11-dev \
  libx11-xcb1 libx86emu3 libxatracker2 libxau-dev libxcb-dri2-0 libxcb-dri3-0 \
  libxcb-glx0 libxcb-present0 libxcb-randr0 libxcb-shm0 libxcb-sync1 \
  libxcb-xfixes0 libxcb1-dev libxdmcp-dev libxfixes3 libxshmfence1 libxxf86vm1 \
  libz3-4 mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers \
  ocl-icd-libopencl1 va-driver-all vainfo x11proto-dev xorg-sgml-doctools \
  xtrans-dev libx11-6

sudo apt install --reinstall --download-only \
  level-zero-dev libigc-dev libigdfcl-dev libigfxcmrt-dev libigfxcmrt7

sudo apt install --reinstall --download-only \
  build-essential bzip2 cpp cpp-11 cpp-12 dctrl-tools dkms dpkg-dev fakeroot \
  fontconfig-config fonts-dejavu-core g++ g++-11 gcc gcc-11 gcc-11-base gcc-12 \
  libalgorithm-diff-perl libalgorithm-diff-xs-perl libalgorithm-merge-perl \
  libasan6 libasan8 libatomic1 libc-dev-bin libc-devtools libc6-dev libcc1-0 \
  libcrypt-dev libdeflate0 libdpkg-perl libfakeroot libfile-fcntllock-perl \
  libfontconfig1 libgcc-11-dev libgcc-12-dev libgd3 libgomp1 libisl23 libitm1 \
  libjbig0 libjpeg-turbo8 libjpeg8 liblsan0 libmpc3 libnsl-dev libquadmath0 \
  libstdc++-11-dev libtiff5 libtirpc-dev libtsan0 libtsan2 libubsan1 libwebp7 \
  libxpm4 linux-headers-6.8.0-49-generic linux-hwe-6.8-headers-6.8.0-49 \
  linux-libc-dev lto-disabled-list make manpages-dev rpcsvc-proto gawk \
  gcc-12-base libc6 libgcc-s1 libstdc++6

sudo apt install --reinstall --download-only \
  bison flex intel-fw-gpu intel-i915-dkms libfl-dev libfl2 m4
