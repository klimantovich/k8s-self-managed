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

#-----------------------------------------------
# Network variables
#-----------------------------------------------
variable "vpc_cidr" {
  description = "VPC CIDR where resources will be placed in"
  type        = string
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "Variable vpc_cidr must contain valid IPv4 CIDRs."
  }
}

#-----------------------------------------------
# k8s self-managed cluster variables
#-----------------------------------------------
variable "master_nodes_count" {
  description = "(Required) Number of master nodes"
  type        = number
  validation {
    condition     = var.master_nodes_count >= 1
    error_message = "Number of master nodes should be >= 1"
  }
}
variable "worker_nodes_count" {
  description = "(Required) Number of worker nodes"
  type        = number
  validation {
    condition     = var.worker_nodes_count >= 0
    error_message = "Worker nodes number should be >= 0"
  }
}

variable "cluster_instances_ami" {
  description = "Default AMI for cluster node instances"
  type        = string
}

variable "master_instances_type" {
  description = "Instance type associated with master nodes"
  type        = string
}

variable "worker_instances_type" {
  description = "Instance type associated with worker nodes"
  type        = string
}

variable "loadbalancer_instances_type" {
  description = "Instance type associated with cluster loadbalancer"
  type        = string
}

variable "loadbalancer_haproxy_version" {
  description = "HAProxy version for loadbalancer"
  type        = string
  default     = "2.4"
}

variable "cluster_kubernetes_version" {
  description = "Kubernetes version for EKS cluster. If you do not specify a value, the latest available version at resource creation is used"
  type        = number
  validation {
    condition     = var.cluster_kubernetes_version >= 1.23
    error_message = "kubernetes version should be v1.23 or newer"
  }
}

variable "install_ingress_controller" {
  description = "If true - install Nginx Ingress Controller on cluster"
  type        = bool
}

#-----------------------------------------------
# Database variables
#-----------------------------------------------
variable "security_group_db_port" {
  description = "DB port for security groups (like 3306 for mysql etc.)"
  type        = number
}

variable "db_allocated_storage" {
  description = "(Required unless a replicate_source_db is provided) The allocated storage in gibibytes"
  type        = number
  validation {
    condition     = var.db_allocated_storage > 0
    error_message = "Allocated storage should be > 0 Gb."
  }
}

variable "db_engine" {
  description = "The engine version to use"
  type        = string
}

variable "db_engine_version" {
  description = "The database engine to use (https://docs.aws.amazon.com/AmazonRDS/latest/APIReference/API_CreateDBInstance.html)"
  type        = string
}

variable "db_instance_class" {
  description = "(Required) The instance type of the RDS instance (example: db.t3.micro)"
  type        = string
  validation {
    condition     = can(regex("db.[a-z]+", var.db_instance_class))
    error_message = "Instance class name should begin from db (db.t3.micro etc)"
  }
}

variable "db_skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted. If true is specified, no DBSnapshot is created"
  type        = bool
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
}

variable "db_user" {
  description = "Database master User which will be used"
  type        = string
}

#-----------------------------------------------
# Argocd variables
#-----------------------------------------------
variable "argocd_repository" {
  description = "ArgoCD Repository URL"
  type        = string
  validation {
    condition     = can(regex("https://.+", var.argocd_repository))
    error_message = "ArgoCD repository url must be https://<URL>"
  }
  default = "https://argoproj.github.io/argo-helm"
}

variable "argocd_chart_create_namespace" {
  description = "Set true if you want ArgoCD to create namespace for it's resources, or false to use default namespace"
  type        = string
}

variable "argocd_chart_namespace" {
  description = "(If variable argocd_chart_create_namespace = true) Name of namespace where argocd resources are located"
  type        = string
}

variable "argocd_chart_version" {
  description = "ArgoCD Chart Version"
  type        = string
}

variable "argocd_values_path" {
  description = "Path to ArgoCD chart values.yaml file"
  type        = string
}

variable "argocd_project_name" {
  description = "ArgoCD custom project name"
  type        = string
}

#-----------------------------------------------
# Project variables
#-----------------------------------------------
variable "project_application_name" {
  description = "ArgoCD application title"
  type        = string
}

variable "project_repository" {
  description = "Project github repository"
  type        = string
  validation {
    condition     = can(regex("https://.+", var.project_repository))
    error_message = "Repository url must be https://<URL>"
  }
}

variable "project_repository_branch" {
  description = "Project github repository branch"
  type        = string
}

variable "project_repository_path" {
  description = "Path to chart folder in project github repo"
  type        = string
}

variable "project_namespace" {
  description = "Kubernetes namespace for project resources"
  type        = string
}

variable "httpAuthUser" {
  description = "User for HTTP Basic Auth"
  type        = string
}

#-----------------------------------------------
# GCP Secret Manager variables
#-----------------------------------------------
variable "gcp_project" {
  description = "Id of GCP project"
  type        = string
}

variable "tgbot_secret_name" {
  description = "Name of GCP Secret where telegram token is"
  type        = string
}
