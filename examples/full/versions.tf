terraform {
  required_version = ">= 1.11"
  required_providers {
    helm = { source = "hashicorp/helm", version = "~> 3.3" }
  }
}

provider "helm" {
  kubernetes = { config_path = pathexpand(var.kubeconfig) }
}
