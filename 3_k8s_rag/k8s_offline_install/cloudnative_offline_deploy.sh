#!/usr/bin/env bash

# You may change the component version if necessary
ARCH="amd64"

CONTAINERD_VER="2.0.4"
RUNC_VER="1.2.6"
CNI_VER="1.3.0"
NERDCTL_VER="2.0.4"
BUILDKIT_VER="0.20.0"

CRICTL_VER="1.31.0"
HELM_VER="3.17.2"
K8S_VER="1.32.2"
RELEASE_VERSION="v0.16.2"
CALICO_VER="3.29.3"

GPUDEV_PLUGIN_VER="0.32.0"

# K8S config
POD_CIDR="10.244.0.0/16"
# the NIC_CIDR is help to determine which NIC to be used by K8s CNI
# default is to use the NIC where default route is bind
NIC_CIDR=${NIC_CIDR}
# k8s api server bind address
# default is to use the NIC where default route is bind
APISERVER_ADDR=${APISERVER_ADDR}

SCRIPTDIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPTNAME=$(basename "$0")
PKGDIR="${SCRIPTDIR}/pkg"
mkdir -p $PKGDIR

source "${SCRIPTDIR}/../prepare/utils.sh"
IMGDIR="${SCRIPTDIR}/../../docker_images"
IMGLIST="$PKGDIR/_image_list.txt"

function _get_os_distro() {
if [ -f /etc/os-release ]; then
  source /etc/os-release
  if [[ "x$ID" != "x" ]]; then
    echo $ID
  else
    echo "unknown"
  fi
elif [ -f /etc/redhat-release ]; then
  echo "rhel"
elif [ -f /etc/lsb-release ]; then
  source /etc/lsb-release
  if [[ "x$DISTRIB_ID" != "x" ]]; then
    echo $DISTRO_ID | tr '[:upper:]' '[:lower:]'
  else
      echo "unknown"
  fi
else
  echo "unknown"
fi
}

function _install_os_pkg() {
  if [[ $OS == "ubuntu" ]]; then
    sudo apt-get -y install $@
  elif [[ $OS == "rhel" ]]; then
    sudo dnf -y install $@
  else
    echo "Unsupported OS $OS"
    exit 1
  fi
}
function _clean_os_docker_ubuntu() {
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; 
  do 
    sudo apt-get -y remove $pkg; 
  done
}

function _clean_os_docker_rhel() {
  sudo dnf -y remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine podman runc
}

function _install_docker_ubuntu() {
  echo "#Add Docker's official GPG key ......"
  sudo apt-get update
  sudo apt-get -y install ca-certificates curl
  sudo install -m 0755 -d /etc/apt/keyrings
  sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
  sudo chmod a+r /etc/apt/keyrings/docker.asc

  echo "#Add the repository to Apt sources ......"
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
  sudo apt-get update
  
  echo "#Install docker engine ......"
  sudo apt-get -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl restart docker
}

function _install_docker_rhel() {
  echo "#Install docker engine ......"
  sudo dnf -y install dnf-plugins-core
  sudo dnf -y config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
  sudo systemctl enable --now docker
  sudo systemctl start docker
}

function install_docker() {
  _clean_os_docker_${OS}
  _install_docker_${OS}
  # manage docker as non-root
  sudo groupadd docker
  sudo usermod -aG docker $USER
  sudo systemctl restart docker
}

function _uninstall_docker_ubuntu() {
  sudo apt-get -y purge docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
  sudo rm /etc/apt/sources.list.d/docker.list
  sudo rm /etc/apt/keyrings/docker.asc
}

function _uninstall_docker_rhel() {
  sudo dnf -y remove docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd
}

function uninstall_docker() {
  _uninstall_docker_${OS}
}

function _get_pkg_runc() {
  echo "#Get Runc ......"
  wget -c -qO $PKGDIR/runc.${ARCH} https://github.com/opencontainers/runc/releases/download/v${RUNC_VER}/runc.${ARCH}
}

function _install_pkg_runc() {
  echo "#Install Runc ......"
  sudo install -m 755 $PKGDIR/runc.${ARCH} /usr/local/sbin/runc
}

function _get_pkg_cni() {
  echo "#Get CNI ......"
  wget -c -qO $PKGDIR/cni-plugins-linux-${ARCH}-v${CNI_VER}.tgz https://github.com/containernetworking/plugins/releases/download/v${CNI_VER}/cni-plugins-linux-${ARCH}-v${CNI_VER}.tgz
}

function _install_pkg_cni() {
  echo "#Install CNI ......"
  sudo mkdir -p /opt/cni/bin
  sudo tar Czxf /opt/cni/bin $PKGDIR/cni-plugins-linux-${ARCH}-v${CNI_VER}.tgz
}

function _get_pkg_containerd() {
  echo "#Get containerd ......"
  wget -c -qO $PKGDIR/containerd-${CONTAINERD_VER}-linux-${ARCH}.tar.gz https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VER}/containerd-${CONTAINERD_VER}-linux-${ARCH}.tar.gz
  wget -c -qO $PKGDIR/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
}

function _install_pkg_containerd() {
  echo "#Install Containerd ......"
  sudo tar Czxf /usr/local $PKGDIR/containerd-${CONTAINERD_VER}-linux-${ARCH}.tar.gz
  sudo rm -rf /usr/local/lib/systemd/system/containerd.service.d
  sudo mkdir -p /usr/local/lib/systemd/system/
  sudo cp $PKGDIR/containerd.service /usr/local/lib/systemd/system/containerd.service
  if [ -z "$http_proxy" ] && [ -z "$https_proxy" ]; then
    echo "containerd proxy setting is not needed"
  else
    sudo mkdir -p /usr/local/lib/systemd/system/containerd.service.d
    cat <<EOF | sudo tee /usr/local/lib/systemd/system/containerd.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=${http_proxy}"
Environment="HTTPS_PROXY=${https_proxy}"
Environment="NO_PROXY=10.96.0.1,10.96.0.0/12,10.0.0.0/8,svc,svc.cluster.local,${no_proxy}"
EOF
  fi

  sudo mkdir -p /etc/containerd
  sudo rm -f /etc/containerd/config.toml
  containerd config default | sudo tee /etc/containerd/config.toml
  sudo sed -i "s/SystemdCgroup = false/SystemdCgroup = true/g" /etc/containerd/config.toml
  if ! grep 'SystemdCgroup = true' /etc/containerd/config.toml
  then
    containerd_config_ver=$(cat /etc/containerd/config.toml | grep version | awk '{print $3'})
    if [[ ${containerd_config_ver} -eq 3 ]]; then
      sudo sed -i "/plugins.'io.containerd.cri.v1.runtime'.containerd.runtimes.runc.options.*/a SystemdCgroup = true" /etc/containerd/config.toml
    else
      sudo sed -i '/plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options.*/a SystemdCgroup = true' /etc/containerd/config.toml
    fi
  fi
  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
  sudo systemctl restart containerd
}

function _get_pkg_nerdctl() {
  echo "#Get nerdctl ......"
  wget -c -qO $PKGDIR/nerdctl-${NERDCTL_VER}-linux-${ARCH}.tar.gz https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VER}/nerdctl-${NERDCTL_VER}-linux-${ARCH}.tar.gz
}

function _install_pkg_nerdctl() {
  echo "#Install nerdctl ......"
  sudo tar Czxf /usr/local/bin $PKGDIR/nerdctl-${NERDCTL_VER}-linux-${ARCH}.tar.gz
}

function _get_pkg_buildkit() {
  echo "#Get buildkit ......"
  wget -c -qO $PKGDIR/buildkit-v${BUILDKIT_VER}.linux-${ARCH}.tar.gz https://github.com/moby/buildkit/releases/download/v${BUILDKIT_VER}/buildkit-v${BUILDKIT_VER}.linux-${ARCH}.tar.gz
  wget -c -qO $PKGDIR/buildkit.service https://raw.githubusercontent.com/moby/buildkit/v${BUILDKIT_VER}/examples/systemd/system/buildkit.service
  wget -c -qO $PKGDIR/buildkit.socket https://raw.githubusercontent.com/moby/buildkit/v${BUILDKIT_VER}/examples/systemd/system/buildkit.socket
}

function _install_pkg_buildkit() {
  echo "#Install buildkit ......"
  sudo tar Czxf /usr/local $PKGDIR/buildkit-v${BUILDKIT_VER}.linux-${ARCH}.tar.gz
  sudo mkdir -p /etc/buildkit
  cat <<EOF | sudo tee /etc/buildkit/buildkitd.toml
[worker.oci]
  enabled = false
[worker.containerd]
  enabled = true
  # namespace should be "k8s.io" for Kubernetes (including Rancher Desktop)
  namespace = "k8s.io"
EOF
  sudo rm -rf /usr/local/lib/systemd/system/buildkit.service.d
  sudo mkdir -p /usr/local/lib/systemd/system/
  
  if [ -z "$http_proxy" ] && [ -z "$https_proxy" ]; then
    echo "containerd proxy setting is not needed"
  else
    sudo mkdir -p /usr/local/lib/systemd/system/buildkit.service.d
    cat <<EOF | sudo tee /usr/local/lib/systemd/system/buildkit.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=${http_proxy}"
Environment="HTTPS_PROXY=${https_proxy}"
Environment="NO_PROXY=10.96.0.1,10.96.0.0/12,10.0.0.0/8,svc,svc.cluster.local,${no_proxy}"
EOF
  fi
  sudo -E cp $PKGDIR/buildkit.service /usr/local/lib/systemd/system/buildkit.service
  sudo -E cp $PKGDIR/buildkit.socket  /usr/local/lib/systemd/system/buildkit.socket
  sudo systemctl daemon-reload
  sudo systemctl enable --now buildkit
  sudo systemctl restart buildkit
}

function _install_k8s_cri() {
  if ! [ -e $PKGDIR/buildkit-v${BUILDKIT_VER}.linux-${ARCH}.tar.gz ]; then
    download_k8s_pkg
  fi
  echo "# Disable swap ......"
  sudo swapoff -a
  sudo sed -i "s/^[^#]\(.*swap\)/#\1/g" /etc/fstab
  echo "# load kernel module for containerd ......"
  cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF
  sudo modprobe overlay
  sudo modprobe br_netfilter
  echo "# Enable IPv4 packet forwarding ......"
  cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
  sudo sysctl --system

  _install_pkg_runc
  _install_pkg_cni
  _install_pkg_containerd
  _install_pkg_nerdctl
  #You may skip buildkit installation if you don't need to build container images.
  _install_pkg_buildkit
}

function _get_pkg_crictl() {
  echo "#Get crictl ......"
  wget -c -qO $PKGDIR/crictl-v${CRICTL_VER}-linux-${ARCH}.tar.gz https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VER}/crictl-v${CRICTL_VER}-linux-${ARCH}.tar.gz
}

function _install_pkg_crictl() {
  echo "# Install crictl ......"
  sudo tar Czxf /usr/local/bin $PKGDIR/crictl-v${CRICTL_VER}-linux-${ARCH}.tar.gz
}

function _get_pkg_k8s_binary() {
  echo "#Get k8s_binary ......"
  curl -o $PKGDIR/kubeadm -L -C - https://dl.k8s.io/release/v${K8S_VER}/bin/linux/${ARCH}/kubeadm
  curl -o $PKGDIR/kubelet -L -C - https://dl.k8s.io/release/v${K8S_VER}/bin/linux/${ARCH}/kubelet
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service" | sed "s:/usr/bin:/usr/local/bin:g" | tee $PKGDIR/kubelet.service
  curl -sSL "https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf" | sed "s:/usr/bin:/usr/local/bin:g" | tee $PKGDIR/10-kubeadm.conf
  curl -o $PKGDIR/kubectl -L -C - https://dl.k8s.io/release/v${K8S_VER}/bin/linux/${ARCH}/kubectl
}

function _install_pkg_k8s_binary() {
  echo "# Install kubeadm, kubelet ......"
  sudo cp $PKGDIR/kubeadm /usr/local/bin/kubeadm && sudo chmod +x /usr/local/bin/kubeadm
  sudo cp $PKGDIR/kubelet /usr/local/bin/kubelet && sudo chmod +x /usr/local/bin/kubelet

  sudo cp $PKGDIR/kubelet.service /usr/lib/systemd/system/kubelet.service
  sudo mkdir -p /usr/local/lib/systemd/system/kubelet.service.d
  sudo cp $PKGDIR/10-kubeadm.conf /usr/local/lib/systemd/system/kubelet.service.d/10-kubeadm.conf
  sudo systemctl enable --now kubelet

  echo "#Install kubectl ......"
  sudo install -o root -g root -m 0755 $PKGDIR/kubectl /usr/local/bin/kubectl
}

function _get_pkg_helm() {
  wget -c -qO $PKGDIR/helm-v${HELM_VER}-linux-${ARCH}.tar.gz https://get.helm.sh/helm-v${HELM_VER}-linux-${ARCH}.tar.gz
}

function _install_pkg_helm() {
  echo "#Install helm ......"
  sudo rm -rf /tmp/helm-extract-temp
  mkdir -p /tmp/helm-extract-temp
  tar Czxf /tmp/helm-extract-temp $PKGDIR/helm-v${HELM_VER}-linux-${ARCH}.tar.gz
  sudo mv /tmp/helm-extract-temp/linux-${ARCH}/helm /usr/local/bin/helm
  rm -rf /tmp/helm-extract-temp
}

function _install_k8s_comp () {
  if ! [ -e $PKGDIR/kubectl ]; then
    download_k8s_pkg
  fi
  _install_pkg_crictl
  _install_pkg_k8s_binary
  _install_pkg_helm
}

function _find_k8s_pod_network () {
  if [ "x${NIC_CIDR}" == "x" ]; then
    interface=$(ip route | awk '/default/ { print $5 }')
    NIC_CIDR=$(ip addr show "$interface" | awk '/inet / { print $2 }')
    if [ "x${APISERVER_ADDR}" == "x" ]; then
      APISERVER_ADDR=$(echo ${NIC_CIDR} | cut -d'/' -f1)
    fi
  fi
  if [ "x${APISERVER_ADDR}" == "x" ]; then
    interface=$(ip route | awk '/default/ { print $5 }')
    if [ -z "$interface}" ]; then
      echo "Error: can NOT find the default route!"
      echo "Please set environment variable APISERVER_ADDR to run this installation script!"
      exit 1
    fi
    APISERVER_ADDR=$(ip addr show "$interface" | awk '/inet / { print $2 }' | cut -d'/' -f1)
  fi
}

function _get_pkg_cni_calico() {
  echo "#Get Calico ......"
  wget -c -qO $PKGDIR/calico.yaml https://raw.githubusercontent.com/projectcalico/calico/v${CALICO_VER}/manifests/calico.yaml
}

function _install_pkg_cni_calico() {
  echo "#Install Calico CNI ......"
  kubectl create -f $PKGDIR/calico.yaml
}


function _load_k8s_images() {
  for image in `cat $IMGLIST`; do
    if ! sudo nerdctl -n k8s.io image inspect $image >/dev/null 2>&1; then
      local imgfile="${IMGDIR}/$(_get_image_filename $image)"
      echo "Load k8s image $image ..."
      sudo nerdctl -n k8s.io image load -i $imgfile
    fi
  done
}

function _setup_k8s_master() {
  echo "# Initialize k8s master node ......"
  _load_k8s_images
  _find_k8s_pod_network
  sudo -E kubeadm init --pod-network-cidr "${POD_CIDR}" --apiserver-advertise-address ${APISERVER_ADDR} --token abcdef.0123456789abcdef --token-ttl 0

  echo "# copy kubeconfig to user home directory ......"
  mkdir -p $HOME/.kube
  sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

  echo "# instal CNI plugin ......"
  _install_pkg_cni_calico
  echo "Sleep 30s for waiting for CNI ready"
  sleep 30

  kubectl get node -owide
  
  echo "K8s master node is ready"
  echo "To join more K8s worker node, please run 'APISERVER_ADDR=${APISERVER_ADDR} $0 -a install_k8s_worker' on your worker nodes if necessary."
  echo "If you only has one K8s node, please run $0 -a k8s_master_untaint on your master node."

  _install_os_pkg bash-completion
  kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
  sudo chmod a+r /etc/bash_completion.d/kubectl
}

function install_k8s_master() {
  _install_k8s_cri
  _install_k8s_comp
  _setup_k8s_master
}

function install_k8s_worker() {
  if [ "x${APISERVER_ADDR}" == "x" ]; then
     echo "Error: Missing APISERVER_ADDR env viriable. Please specify it."
     exit 1
  else
    _load_k8s_images
    _install_k8s_cri
    _install_k8s_comp
    echo "# Join k8s worker node to master node ......"
    sudo -E kubeadm join ${APISERVER_ADDR}:6443 --token abcdef.0123456789abcdef --discovery-token-unsafe-skip-ca-verification
  fi
}

function k8s_reset() {
  sudo kubeadm reset
  sudo nerdctl -n k8s.io system prune
  echo "Please manually reset iptables/ipvs if necessary"
}

function k8s_master_untaint() {
  kubectl taint nodes --all node-role.kubernetes.io/control-plane-
  kubectl label nodes --all node.kubernetes.io/exclude-from-external-load-balancers-
}

function _wait_for_all_pod_ready() {
  ns=$1
  timeout=${2:-60s}
  echo "Wait for all pods in namespace $ns to be ready ..."
  for pod in `kubectl -n $ns get pod -oname`;
  do
    if ! kubectl -n $ns wait --for=condition=Ready --timeout $timeout $pod; then
      echo "Error: pod $pod in NS $ns not ready in $timeout seconds."
      echo "Please check..."
      exit 1
    fi
  done
}

function install_gpu_device_plugin() {
  echo "#Install k8s GPU device plugin ......"
  #Start NFD
  kubectl apply -f $PKGDIR/intel-device-plugins-for-kubernetes-nfd-${GPUDEV_PLUGIN_VER}.yaml
  # Create NodeFeatureRules for detecting GPUs on nodes
  kubectl apply -f $PKGDIR/intel-device-plugins-for-kubernetes-nfdrules-${GPUDEV_PLUGIN_VER}.yaml
  sleep 5
  _wait_for_all_pod_ready node-feature-discovery
  # Create GPU plugin daemonset
  kubectl create ns intel-gpu-plugin || true
  kubectl -n intel-gpu-plugin apply -f $PKGDIR/intel-device-plugins-for-kubernetes-gpuplugin-${GPUDEV_PLUGIN_VER}.yaml
  sleep 5
  _wait_for_all_pod_ready intel-gpu-plugin
}

function verify_intel_gpu() {
set +e
cat <<EOF | kubectl apply -f -
apiVersion: batch/v1
kind: Job
metadata:
  name: intelgpu-demo-job
  labels:
    jobgroup: intelgpu-demo
spec:
  template:
    metadata:
      labels:
        jobgroup: intelgpu-demo
    spec:
      restartPolicy: Never
      containers:
        - name: intelgpu-demo-job-1
          image: lianhao/intel-opencl-icd:0.32.0
          imagePullPolicy: IfNotPresent
          command: [ "clinfo" ]
          resources:
            limits:
              gpu.intel.com/i915: 1
EOF

kubectl wait --for=condition=complete job/intelgpu-demo-job --timeout 90s
pod=$(kubectl get pod -l jobgroup=intelgpu-demo -oname)
devnum=$(kubectl logs $pod | grep 'Number of devices' | awk '{print $4}')
kubectl delete job/intelgpu-demo-job

if [ $devnum -eq 1 ]; then
    echo "Success: Found 1 GPU in pod"
else
    echo "Faiulre: Not found 1 GPU in pod"
fi
}

function download_k8s_pkg() {
  for comp in `grep 'function _get_pkg_.*()' ${SCRIPTDIR}/${SCRIPTNAME} | awk '{print substr($2, 10)}' | cut -d'(' -f1`;
  do
    _get_pkg_$comp
  done
  echo "All k8s related pkgs are downloaded."
  echo "Generate image list used by kubeadm ..."
  chmod +x $PKGDIR/kubeadm
  $PKGDIR/kubeadm config images list | tee "${IMGLIST}"
  echo "Generate image list used by cni_calico ..."
  cat $PKGDIR/calico.yaml | grep 'image: ' | sort -u | awk '{ print $2 }' | tee -a "${IMGLIST}"
  echo "Generate image list used by GPU device plugin ..."
  cat $PKGDIR/intel-device-plugins-for-kubernetes-*-${GPUDEV_PLUGIN_VER}.yaml | grep 'image: ' | sort -u | awk '{ print $2 }' | tee -a "${IMGLIST}"
  echo "nicolaka/netshoot:v0.13" >> "${IMGLIST}"
  echo "lianhao/intel-opencl-icd:0.32.0" >> "${IMGLIST}"
  echo "Image list is succesfully generated at ${IMGLIST}."
}


OS=$(_get_os_distro)
case $OS in
  ubuntu)
    echo "Ubuntu Linux is verified"
    ;;
  unknown)
    echo "Unknown Linux"
    exit 1
    ;;
  *)
    echo "Unsupported OS $OS"
    exit 1
    ;;
esac


function usage() {
    echo "Usage: $0 [ -a | --action ] <action> [ options ]"
    echo "Available actions:"
    echo "    install_docker: install latest docker engine community version"
    echo "    uninstall_docker: uninstall docker"
    echo "    install_k8s_master: install K8s master node, must run on k8s master node"
    echo "    install_k8s_worker: install K8s worker node, must run on k8s worker node"
    echo "    k8s_reset: reset k8s node, must run on k8s woker node first, then run on k8s master node"
    echo "    k8s_master_untaint: untaint mater node for pod scheduling, must run on k8s m8s master node"
    echo "    download_k8s_pkg: download all k8s related packages for later use in $PKGDIR directory"
    echo "    install_gpu_device_plugin: install Intel GPU k8s device plugin"
    echo "    verify_intel_gpu: verify Intel GPU k8s device plugin is working and system has at least 1 supported Intel GPU"
    echo "Available options:"
    echo "    -d --debug: turn on debug"
    echo "    -h --help: show usage"
}

options=$(getopt -o "a:dh" -l "action:,debug,help" -- "$@")
if [ $? -ne 0 ]; then
  echo "Error parsing options"
  usage
  exit 1
fi

eval set -- "$options"
while true; do
  case "$1" in
    -a|--action)
      action=$2
      shift 2
      ;;
    -d|--debug)
      debug=True
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    *)
      echo "Invalid option $1"
      usage
      exit 1
      ;;
  esac
done

if [ -z $action ]; then usage; exit 1; fi

if [[ $debug == "True" ]]; then set -x; fi
set -e
$action
set +ex
