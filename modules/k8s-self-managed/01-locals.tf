locals {
  common_name_prefix = "k8s"
  nodes_total_number = var.master_nodes_count + var.worker_nodes_count

  # Subnets for worker nodes & control plane
  master_nodes_subnet = var.private_subnet_ids[0]
  worker_nodes_subnet = var.private_subnet_ids[1]

  # Generate prefix for static private IPs for cluster nodes
  master_nodes_subnet_prefix = regex("^\\d{1,3}.\\d{1,3}.\\d{1,3}", var.private_subnet_cidrs[0]) # String subnet address without host ip                                                                    # ip, which worker nodes ips start from
  worker_nodes_subnet_prefix = regex("^\\d{1,3}.\\d{1,3}.\\d{1,3}", var.private_subnet_cidrs[1]) # String subnet address without host ip

  # Secrets names & default placeholder
  secret_placeholder                  = "default"
  kubeadm_token_secret_name           = "KubeadmJoinToken"
  kubeadm_ca_secret_name              = "KubeadmCA"
  kubeconfig_secret_name              = "KubeadmKubeconfig"
  kubeadm_certificate_key_secret_name = "KubeadmCertificateKey"
}
