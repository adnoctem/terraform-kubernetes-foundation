provider "kubernetes" {
  config_path    = pathexpand(var.kubeconfig)
  config_context = var.kube_context
}
module "configuration" {
  source = "../../../modules/configuration"

  step_issuers = {
    mesh = {
      namespace     = "istio-system"
      url           = var.ca_url
      ca_bundle_pem = var.root_ca_pem
      provisioner = {
        name         = var.provisioner_name
        kid          = var.provisioner_kid
        password_ref = { name = var.provisioner_secret, key = "password" }
      }
    }
  }
  trusted_roots = {
    mesh-root = { namespace = "cert-manager", pem = var.root_ca_pem }
  }
  argo_applications = var.bootstrap_application_spec == null ? {} : {
    bootstrap = { spec_yaml = var.bootstrap_application_spec }
  }
}
