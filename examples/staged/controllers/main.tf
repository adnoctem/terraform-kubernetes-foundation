module "foundation" {
  source = "../../.."

  enable_cilium              = true
  cilium_istio_compatibility = true
  cilium                     = { values = var.cilium_values }
  enable_cert_manager        = true
  enable_step_issuer         = true
  enable_step_certificates   = var.in_cluster_ca
  step_certificates          = { values = var.ca_values }
  enable_istio_base          = true
  enable_argocd              = true
}
