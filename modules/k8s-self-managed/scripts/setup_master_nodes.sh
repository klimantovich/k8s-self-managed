#!/bin/bash

#---------------------------------------------------------
# Create Config For kubeadm
#---------------------------------------------------------
create_kubeadm_init_config() {

IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
HOSTNAME=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

cat <<EOF | tee /etc/kubernetes/kubeadm-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
bootstrapTokens:
  - groups:
      - system:bootstrappers:kubeadm:default-node-token
    ttl: 24h0m0s
    usages:
      - signing
      - authentication
localAPIEndpoint:
  advertiseAddress: $IP
  bindPort: ${apiserver_port}
nodeRegistration:
  criSocket: unix:///var/run/crio/crio.sock
  imagePullPolicy: IfNotPresent
  name: $HOSTNAME
  kubeletExtraArgs:
    cloud-provider: external
  taints: null

---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
apiServer:
  timeoutForControlPlane: 4m0s
  extraArgs:
    cloud-provider: external
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager:
  extraArgs:
    cloud-provider: external
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
controlPlaneEndpoint: ${control_plane_endpoint}:${apiserver_port}
imageRepository: registry.k8s.io
kubernetesVersion: ${kubernetes_version}.0
networking:
  dnsDomain: cluster.local
  podSubnet: ${pod_subnet_cidr}
  serviceSubnet: ${service_subnet_cidr}
scheduler: {}
EOF

}


#---------------------------------------------------------
# Create Config For Kubeadm Join
#---------------------------------------------------------
create_kubeadm_join_config() {

token=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString | tr -s '\n')
ca_hash=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString | tr -s '\n')
ip=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
certificate_key=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_certificate_key_secret_name} | jq -r .SecretString | tr -s '\n')
hostname=$(curl -s http://169.254.169.254/latest/meta-data/local-hostname)

cat <<EOF | tee /etc/kubernetes/kubeadm-join.yaml
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: JoinConfiguration
discovery:
  bootstrapToken:
    token: $token
    apiServerEndpoint: ${control_plane_endpoint}:${apiserver_port}
    caCertHashes:
      - sha256:$ca_hash
controlPlane:
  localAPIEndpoint:
    advertiseAddress: $ip
    bindPort: ${apiserver_port}
  certificateKey: $certificate_key
nodeRegistration:
  name: $hostname
  kubeletExtraArgs:
    cloud-provider: external
EOF

}


#---------------------------------------------------------
# Kubeadm Join
#---------------------------------------------------------
kubeadm_join() {
  create_kubeadm_join_config
  kubeadm join --config /etc/kubernetes/kubeadm-join.yaml
}


#---------------------------------------------------------
# Kubeadm Init Cluster
#---------------------------------------------------------
kubeadm_init() {
  create_kubeadm_init_config

  kubeadm init --config=/etc/kubernetes/kubeadm-config.yaml

  # Wait for kubeconfig created
  until [ -f /etc/kubernetes/admin.conf ]
  do
    echo "Wait for kubeconfig created"
    sleep 5
  done

  mkdir ~/.kube
  cp /etc/kubernetes/admin.conf ~/.kube/config
  export KUBECONFIG=/etc/kubernetes/admin.conf

  sleep 30
}


#---------------------------------------------------------
# Install Cloud Controller Manager
#---------------------------------------------------------
setup_ccm() {
  git clone https://github.com/kubernetes/cloud-provider-aws.git tmp/cloud-provider-aws

  kubectl create -k tmp/cloud-provider-aws/examples/existing-cluster/base 
  # Wait for AWS CCM Initialized
  until kubectl get -n kube-system daemonset | grep 'aws-cloud'; do
    echo "Wait for AWS CCM"
    sleep 10
    kubectl create -k tmp/cloud-provider-aws/examples/existing-cluster/base
  done

  
}


#---------------------------------------------------------
# Setup Network Plugin (Calico)
#---------------------------------------------------------
setup_cni_plugin() {
  kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${calico_version}/manifests/tigera-operator.yaml
  # Wait for Tigera operator initialized
  until kubectl get -n tigera-operator pods | grep 'Running'; do
    echo "Wait for Tigera Operator initialized"
    sleep 10
    kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v${calico_version}/manifests/tigera-operator.yaml
  done

cat <<EOF | tee /etc/kubernetes/custom-resources.yaml
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    bgp: Disabled
    ipPools:
      - blockSize: 26
        cidr: ${pod_subnet_cidr}
        encapsulation: VXLANCrossSubnet
        natOutgoing: Enabled
        nodeSelector: all()
EOF
  kubectl apply -f /etc/kubernetes/custom-resources.yaml

  # Wait for Calico initialized
  until kubectl get -n calico-system pods | grep 'Running'; do
    echo "Wait for Calico initialized"
    sleep 10
    kubectl apply -f /etc/kubernetes/custom-resources.yaml
  done
}


#---------------------------------------------------------
# Setup Nginx Ingress Controller
#---------------------------------------------------------
install_ingress_controller() {

  kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/aws/deploy.yaml

  # Set Ingress Class Default For Cluster
cat <<EOF | tee /etc/kubernetes/ingress-class.yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/instance: ingress-nginx
    app.kubernetes.io/name: ingress-nginx
    app.kubernetes.io/part-of: ingress-nginx
    app.kubernetes.io/version: 1.10.0
    ingressclass.kubernetes.io/is-default-class: "true"
  name: nginx
spec:
  controller: k8s.io/ingress-nginx
EOF

  kubectl apply -f /etc/kubernetes/ingress-class.yaml

  # Wait Ingress Setup
  until kubectl get -n ingress-nginx pods | grep 'Running'; do
    echo "Wait for Ingress Controller Initialized"
    sleep 10
  done

  # Fix for "failed to call webhook: ... context deadline exceeded" issue
  kubectl delete validatingwebhookconfiguration ingress-nginx-admission

}


#---------------------------------------------------------
# Set up cluster secrets
#---------------------------------------------------------
setup_cluster_secrets() {
  CA_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt \
    | openssl rsa -pubin -outform der 2>/dev/null \
    | openssl dgst -sha256 -hex \
    | sed 's/^.* //')
  TOKEN=$(kubeadm token create)
  CERTIFICATE_KEY=$(kubeadm init phase upload-certs --upload-certs | tail -n 1)

  aws secretsmanager update-secret --secret-id ${kubeadm_ca_secret_name} --secret-string $CA_HASH
  aws secretsmanager update-secret --secret-id ${kubeadm_certificate_key_secret_name} --secret-string $CERTIFICATE_KEY
  aws secretsmanager update-secret --secret-id ${kubeadm_token_secret_name} --secret-string $TOKEN
  aws secretsmanager update-secret --secret-id ${kubeconfig_secret_name} --secret-string "$(cat /etc/kubernetes/admin.conf)"

}


#---------------------------------------------------------
# Wait For Cluster Secrets (for non-initial master nodes)
#---------------------------------------------------------
wait_for_cluster_secrets() {
  ca_hash=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString | tr -s '\n')
  cert_key=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_certificate_key_secret_name} | jq -r .SecretString | tr -s '\n')
  token=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString | tr -s '\n')

  # Wait while init node updates CA hash secret
  while [[ -z "$ca_hash" || "$ca_hash" == "${secret_placeholder}" ]]
  do
    echo "Waiting the CA Hash"
    ca_hash=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString | tr -s '\n')
    sleep 5
  done

  # Wait while init node updates Cluster Certificate Key secret
  while [[ -z "$cert_key" || "$cert_key" == "${secret_placeholder}" ]]
  do
    echo "Waiting the Certificate Key"
    cert_key=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_certificate_key_secret_name} | jq -r .SecretString | tr -s '\n')
    sleep 5
  done

  # Wait while init node updates Token secret
  while [[ -z "$token" || "$token" == "${secret_placeholder}" ]]
  do
    echo "Waiting the Certificate Key"
    token=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString | tr -s '\n')
    sleep 5
  done
}


#---------------------------------------------------------
# Wait For Kubeadm Init (for non-initial master nodes)
#---------------------------------------------------------
wait_for_kubeadm_init() {
  while [ true ]
  do
    curl --silent -o /dev/null ${control_plane_endpoint}:${apiserver_port}
    if [[ "$?" -eq 0 ]]; then
      break
    fi
    sleep 10
    echo "Wait for ApiServer endpoint"
  done
}

#---------------------------------------------------------
#---------------------------------------------------------
# MAIN FLOW
#---------------------------------------------------------
export AWS_DEFAULT_REGION=${aws_default_region}
INITIAL_NODE_ID=$(aws ec2 describe-instances \
  --filters Name=tag:role,Values=master Name=instance-state-name,Values=running \
  --query 'sort_by(Reservations[].Instances[], &LaunchTime)[:-1].[InstanceId]' --output text | head -n1)
THIS_NODE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)

if [[ "$INITIAL_NODE_ID" == "$THIS_NODE_ID" || -z "$INITIAL_NODE_ID" ]]; then
  kubeadm_init
  setup_ccm
  setup_cni_plugin
  setup_cluster_secrets
  %{ if install_ingress_controller }
  install_ingress_controller
  %{ endif }
else
  wait_for_cluster_secrets
  wait_for_kubeadm_init
  kubeadm_join
fi


