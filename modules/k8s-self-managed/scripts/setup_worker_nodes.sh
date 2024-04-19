#!/bin/bash

#---------------------------------------------------------
# Wait For Cluster Secrets (for non-initial master nodes)
#---------------------------------------------------------
wait_for_cluster_secrets() {
  # WAIT FOR SECRETS
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
  # WAIT FOR ENDPOINT
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
# Create Config For Kubeadm Join
#---------------------------------------------------------
create_kubeadm_join_config() {

token=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_token_secret_name} | jq -r .SecretString | tr -s '\n')
ca_hash=$(aws secretsmanager get-secret-value --secret-id ${kubeadm_ca_secret_name} | jq -r .SecretString | tr -s '\n')
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
#---------------------------------------------------------
# MAIN FLOW
#---------------------------------------------------------
# SET REGION
export AWS_DEFAULT_REGION=${aws_default_region}
# REGION:::
echo $AWS_DEFAULT_REGION

wait_for_cluster_secrets
wait_for_kubeadm_init
kubeadm_join
