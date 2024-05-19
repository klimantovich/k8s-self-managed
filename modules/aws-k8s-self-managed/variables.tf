#----------------------------------------
# Provider variables
#----------------------------------------
variable "aws_region" {
  description = "(Required) AWS region for VPC resources"
  type        = string
  default     = ""
  validation {
    condition     = can(regex("[a-z][a-z]-[a-z]+-[1-9]", var.aws_region))
    error_message = "Must be valid AWS Region name."
  }
}

variable "environment" {
  description = "Environment prefix"
  type        = string
  default     = "dev"
}

#----------------------------------------
# RSA key variables
#----------------------------------------
variable "rsa_key_name" {
  description = "Name of the RSA key name for k8s instances"
  type        = string
  default     = "cluster-key"
}

#----------------------------------------
# VPC settings
#----------------------------------------
variable "vpc_id" {
  description = "VPC id where cluster is located"
  type        = string
}

variable "private_subnet_ids" {
  description = "IDs of private subnets for k8s cluster. Minimum 2"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_ids) > 1
    error_message = "There are should be 2 or more private subnets"
  }
}

variable "private_subnet_cidrs" {
  description = "CIDRs of private subnets for k8s cluster. Minimum 2"
  type        = list(string)
  validation {
    condition     = length(var.private_subnet_cidrs) > 1
    error_message = "There are should be 2 or more private subnets"
  }
}

variable "public_subnet_ids" {
  description = "IDs of public subnets for k8s cluster."
  type        = list(string)
}

#----------------------------------------
# Cluster Instances Variables
#----------------------------------------
variable "master_nodes_count" {
  description = "Number of master nodes. Should be minimun 1 and not even."
  type        = number
  default     = 1
  validation {
    condition     = var.master_nodes_count % 2 != 0
    error_message = "Only not even nubmer of master nodes are accepted!"
  }
}

variable "worker_nodes_count" {
  description = "Number of worker nodes"
  type        = number
  default     = 0
}

variable "instances_ami" {
  description = "AMI for k8s nodes (Required)"
  type        = string
}

variable "loadbalancer_instances_type" {
  description = "Instance type associated with cluster loadbalancer"
  type        = string
}

variable "master_instance_type" {
  description = "Instance type for Master Nodes"
  type        = string
}

variable "worker_instance_type" {
  description = "Instance type for Worker Nodes"
  type        = string
}


#----------------------------------------
# Cluster Configs variables
#----------------------------------------
variable "kubernetes_version" {
  description = "Version of Kubernetes Engine"
  type        = string
  default     = "1.29"
}

variable "apiserver_port" {
  description = "API Server port. Default to 6443"
  type        = number
  default     = 6443
}

variable "crio_version" {
  description = "Version of CRI-O runtime"
  type        = string
  default     = "1.24"
}

variable "pod_subnet_cidr" {
  description = "Cluster subnet cidr for pods"
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_subnet_cidr" {
  description = "Cluster subnet cidr for services"
  type        = string
  default     = "10.96.0.0/12"
}

variable "calico_version" {
  description = "Version of Calico network plugin"
  type        = string
  default     = "3.27.3"
}

variable "install_ingress_controller" {
  description = "If true - install Nginx Ingress Controller on cluster"
  type        = bool
  default     = false
}

variable "ingress_http_nodePort" {
  description = "Port for HTTP connections, which will be expose on cluster nodes to access via ingress (type: NodePort, range 30000-32767)"
  type        = number
  default     = 30080
  validation {
    condition     = var.ingress_http_nodePort >= 30000 && var.ingress_http_nodePort <= 32767
    error_message = "Port for ingress HTTP connections should be in range from 30000 to 32767"
  }
}

variable "ingress_https_nodePort" {
  description = "Port for HTTPS connections, which will be expose on cluster nodes to access via ingress (type: NodePort, range 30000-32767)"
  type        = number
  default     = 30443
  validation {
    condition     = var.ingress_https_nodePort >= 30000 && var.ingress_https_nodePort <= 32767
    error_message = "Port for ingress HTTPS connections should be in range from 30000 to 32767"
  }
}

variable "install_cert_manager" {
  description = "If true - install Cert Manager on cluster"
  type        = bool
  default     = false
}

variable "cert_manager_version" {
  description = "Version of Cert Manager installed on cluster"
  type        = string
  default     = "1.14.5"
}
