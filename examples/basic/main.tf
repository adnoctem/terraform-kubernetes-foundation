provider "helm" {
  kubernetes = { config_path = pathexpand(var.kubeconfig), config_context = var.kube_context }
}
module "foundation" {
  source              = "../.."
  enable_cert_manager = true
  cert_manager = {
    values = [yamlencode({ replicaCount = 2 })]
  }
}
