mock_provider "helm" {
  mock_resource "helm_release" { defaults = { status = "deployed" } }
}
variables {
  write_only_values        = {}
  enable_cilium            = true
  enable_cert_manager      = true
  enable_step_certificates = true
  enable_step_issuer       = true
  enable_istio             = true
  enable_istio_csr         = true
  enable_argocd            = true
  pki                      = { issuer_name = "mesh", root_ca_config_map = "mesh-root" }
  step_certificates        = { values = ["bootstrap:\n  enabled: false\nexistingSecrets:\n  enabled: true\n"] }
}
run "render_sidecar" {
  command = apply
  variables { istio = { mode = "sidecar" } }
  assert {
    condition     = length(output.releases) == 9
    error_message = "The selected mesh mode must create the correct component set."
  }
  assert {
    condition     = yamldecode(local.integration_values.istio_csr[0]).app.certmanager.issuer.name == "mesh" && yamldecode(local.integration_values.istiod[1]).env.ENABLE_CA_SERVER == "false" && yamldecode(local.integration_values.cilium[0]).cni.exclusive == false
    error_message = "Trust, CA endpoint, and CNI coexistence must be wired together."
  }
}
run "render_ambient" {
  command = apply
  variables { istio = { mode = "ambient" } }
  assert {
    condition     = length(output.releases) == 10
    error_message = "The selected mesh mode must create the correct component set."
  }
  assert {
    condition     = yamldecode(local.integration_values.istio_csr[0]).app.certmanager.issuer.name == "mesh" && yamldecode(local.integration_values.istiod[1]).env.ENABLE_CA_SERVER == "false" && yamldecode(local.integration_values.cilium[0]).cni.exclusive == false
    error_message = "Trust, CA endpoint, and CNI coexistence must be wired together."
  }
  assert {
    condition     = yamldecode(local.integration_values.istio_csr[0]).app.server.caTrustedNodeAccounts == "istio-system/ztunnel" && yamldecode(local.integration_values.ztunnel[0]).caAddress == "cert-manager-istio-csr.cert-manager.svc:443"
    error_message = "Ambient CSR authentication and the node proxy must share the configured identity and endpoint."
  }
}
