#!/bin/bash

#---------------------------------------------------------
# Forwarding IPv4 and letting iptables see bridged traffic
#---------------------------------------------------------
enable_modules(){
  cat <<EOF | tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

  cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

  modprobe overlay
  modprobe br_netfilter

  sysctl --system
}

#---------------------------------------------------------
# Pre-installation steps
#---------------------------------------------------------
pre_install() {
  apt-get update && apt-get upgrade -y

  hostnamectl set-hostname $(curl -s http://169.254.169.254/latest/meta-data/local-hostname)
  swapoff -a
  sed -i '/swap/d' /etc/fstab
  mount -a
  ufw disable

  apt-get install -y \
    awscli \
    jq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg2 \
    openssl \
    software-properties-common \
    gpg

  enable_modules
}

#---------------------------------------------------------
# Install Container Runtime (CRI-O)
#---------------------------------------------------------
install_crio() {
  OS=xUbuntu_22.04
  CRIO_VERSION=${crio_version}
  cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list
deb https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/ /
EOF
  cat <<EOF | sudo tee /etc/apt/sources.list.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION.list
deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable:/cri-o:/$CRIO_VERSION/$OS/ /
EOF

  # Add the GPG key for the CRI-O repository
  curl -L https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_VERSION/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -
  curl -L https://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/$OS/Release.key | sudo apt-key --keyring /etc/apt/trusted.gpg.d/libcontainers.gpg add -

  apt-get update
  apt-get install -y \
    cri-o \
    cri-o-runc \
    cri-tools
  systemctl daemon-reload
  systemctl start crio
  systemctl enable crio
}


#---------------------------------------------------------
# Install K8s Utils (kubeadm, kubectl, kubelet)
#---------------------------------------------------------
set_k8s_repos() {
  # Download the public signing key for the Kubernetes package repositories
  curl -fsSL https://pkgs.k8s.io/core:/stable:/v${kubernetes_version}/deb/Release.key | \
    sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  # Add the appropriate Kubernetes apt repository
  echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${kubernetes_version}/deb/ /' \
    | sudo tee /etc/apt/sources.list.d/kubernetes.list
}

setup_k8s_utils() {
  set_k8s_repos

  apt-get update
  apt-get install -y \
    kubelet \
    kubeadm \
    kubectl
  apt-mark hold \
    kubelet \
    kubeadm \
    kubectl
  
  # (Optional) Enable the kubelet service before running kubeadm
  systemctl enable --now kubelet

  # Set Kubelet node IP
  local_ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
  echo "KUBELET_EXTRA_ARGS=--node-ip=$local_ip" | sudo tee /etc/default/kubelet > /dev/null
}

#---------------------------------------------------------
# MAIN FLOW
#---------------------------------------------------------
pre_install
install_crio
setup_k8s_utils