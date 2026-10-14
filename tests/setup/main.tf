terraform {
  required_version = ">= 1.11"
  required_providers {
    helm = { source = "hashicorp/helm", version = "~> 3.3" }
  }
}
resource "terraform_data" "values" {
  input = { name = "computed", values = "replicaCount: 2" }
}
module "subject" {
  source        = "../.."
  enable_argocd = true
  argocd        = { name = terraform_data.values.output.name, values = [terraform_data.values.output.values] }
}
output "keys" {
  value       = keys(module.subject.releases)
  description = "Known component keys despite computed release values."
}
