locals {
  common_name_prefix = "k8s"
  nodes_total_number = var.master_nodes_count + var.worker_nodes_count

  # Subnets for loadbalancer, worker nodes & control plane
  loadbalancer_subnet = var.public_subnet_ids[0]
  master_nodes_subnet = var.private_subnet_ids[0]
  worker_nodes_subnet = var.private_subnet_ids[1]

  # Generate prefix for static private IPs for cluster nodes
  master_nodes_subnet_prefix = regex("^\\d{1,3}.\\d{1,3}.\\d{1,3}", var.private_subnet_cidrs[0]) # String subnet address without host ip                                                                    # ip, which worker nodes ips start from
  worker_nodes_subnet_prefix = regex("^\\d{1,3}.\\d{1,3}.\\d{1,3}", var.private_subnet_cidrs[1]) # String subnet address without host ip

  # Generate static private IPs for cluster nodes
  ip_offset = 10
  master_nodes_ips = formatlist(
    "${local.master_nodes_subnet_prefix}.%s", range(local.ip_offset, var.master_nodes_count + local.ip_offset)
  )
  worker_nodes_ips = formatlist(
    "${local.worker_nodes_subnet_prefix}.%s", range(local.ip_offset, var.worker_nodes_count + local.ip_offset)
  )
  cluster_nodes_ips = concat(local.master_nodes_ips, local.worker_nodes_ips)

  # Secrets names & default placeholder
  secret_placeholder                  = "default"
  kubeadm_token_secret_name           = "Kubeadm-Join-Token"
  kubeadm_ca_secret_name              = "Kubeadm-CA"
  kubeadm_ca_hash_secret_name         = "Kubeadm-CA-hash"
  kubeconfig_secret_name              = "Kubeadm-Kubeconfig"
  kubeadm_certificate_key_secret_name = "Kubeadm-CertificateKey"
}
