#----------------------------------------
# Templating Master Nodes Installation Script
#----------------------------------------
data "template_cloudinit_config" "k8s_master" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/prepare_instances.sh", {
      crio_version       = var.crio_version
      kubernetes_version = var.kubernetes_version
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup_master_nodes.sh", {
      aws_default_region                  = var.aws_region
      kubernetes_version                  = var.kubernetes_version
      apiserver_port                      = var.apiserver_port
      control_plane_endpoint              = aws_lb.api_server.dns_name
      pod_subnet_cidr                     = var.pod_subnet_cidr
      service_subnet_cidr                 = var.service_subnet_cidr
      calico_version                      = var.calico_version
      kubeadm_ca_secret_name              = local.kubeadm_ca_secret_name
      kubeadm_certificate_key_secret_name = local.kubeadm_certificate_key_secret_name
      kubeadm_token_secret_name           = local.kubeadm_token_secret_name
      kubeconfig_secret_name              = local.kubeconfig_secret_name
      secret_placeholder                  = local.secret_placeholder
      install_ingress_controller          = var.install_ingress_controller
    })
  }

}


#----------------------------------------
# Templating Worker Nodes Installation Script
#----------------------------------------
data "template_cloudinit_config" "k8s_worker" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/prepare_instances.sh", {
      crio_version       = var.crio_version
      kubernetes_version = var.kubernetes_version
    })
  }

  part {
    content_type = "text/x-shellscript"
    content = templatefile("${path.module}/scripts/setup_worker_nodes.sh", {
      kubeadm_ca_secret_name              = local.kubeadm_ca_secret_name
      kubeadm_certificate_key_secret_name = local.kubeadm_certificate_key_secret_name
      kubeadm_token_secret_name           = local.kubeadm_token_secret_name
      secret_placeholder                  = local.secret_placeholder
      apiserver_port                      = var.apiserver_port
      control_plane_endpoint              = aws_lb.api_server.dns_name
      aws_default_region                  = var.aws_region
    })
  }

}
