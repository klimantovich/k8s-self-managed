resource "terraform_data" "set_local_kubeconfig" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      kubeconfig=$(aws secretsmanager get-secret-value --secret-id ${local.kubeconfig_secret_name} | jq -r .SecretString | tr -s '\n')
      while [[ -z "$kubeconfig" || "$kubeconfig" == "${local.secret_placeholder}" ]]
      do
        sleep 10
        kubeconfig=$(aws secretsmanager get-secret-value --secret-id ${local.kubeconfig_secret_name} | jq -r .SecretString | tr -s '\n')
      done
      aws secretsmanager get-secret-value --secret-id ${local.kubeconfig_secret_name} | jq -r .SecretString > ~/.kube/config
    EOT
  }

  depends_on = [aws_secretsmanager_secret.kubeconfig_secret]
}


resource "terraform_data" "wait_for_cluster_initialization" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      nodes_ready=$(kubectl get nodes | grep 'Ready' | wc -l | tr -d ' ')
      while [[ "$nodes_ready" != "${local.nodes_total_number}" ]]
      do
        sleep 10
        nodes_ready=$(kubectl get nodes | grep 'Ready' | wc -l | tr -d ' ')
      done
    EOT
  }

  depends_on = [terraform_data.set_local_kubeconfig]
}
