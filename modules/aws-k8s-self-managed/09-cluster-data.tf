#----------------------------------------
# Wait for cluster initialization
#----------------------------------------
resource "terraform_data" "set_local_kubeconfig" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ssh -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip} "test -e /tmp/kubeconfig.conf"
      while [[ $? != 0 ]]
      do
        echo "Waiting For Kubeconfig..."
        sleep 10
        ssh -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip} "test -e /tmp/kubeconfig.conf"
      done
      scp -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip}:/tmp/kubeconfig.conf ~/.kube/config
    EOT
  }

  depends_on = [module.loadbalancer]
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


#----------------------------------------
# Retreive CA certificate
#----------------------------------------
resource "terraform_data" "get_ca_crt" {

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command     = <<-EOT
      ssh -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip} "test -e /tmp/ca.crt"
      while [[ $? != 0 ]]
      do
        echo "Waiting For Kubeconfig..."
        sleep 10
        ssh -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip} "test -e /tmp/ca.crt"
      done
      scp -i ./cluster-key.pem -o StrictHostKeyChecking=no ubuntu@${module.loadbalancer.public_ip}:/tmp/ca.crt ./ca.crt
    EOT
  }

  depends_on = [module.loadbalancer]
}

