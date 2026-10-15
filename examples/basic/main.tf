provider "helm" {
  kubernetes = { config_path = pathexpand(var.kubeconfig), config_context = var.kube_context }
}
module "foundation" {
  source              = "../.."
  release_defaults    = { timeout = 900 }
  enable_cert_manager = true
  cert_manager = {
    values_object    = { replicaCount = 2 }
    service_accounts = { controller = { annotations = { "example.com/team" = "platform" } } }
  }
}
