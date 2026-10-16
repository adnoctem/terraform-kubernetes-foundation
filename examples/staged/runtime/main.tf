module "foundation" {
  source           = "../../.."
  enable_istio     = true
  enable_istio_csr = true
  istio            = { mode = var.istio_mode, manage_base = false }
  pki              = { issuer_name = "mesh", root_ca_config_map = "mesh-root" }
}
