mock_provider "helm" {
  mock_resource "helm_release" { defaults = { status = "deployed" } }
}
# Explicit ephemeral input works around older Terraform native-test defaults.
variables { write_only_values = {} }
run "disabled_by_default" {
  command = plan
  assert {
    condition     = length(output.releases) == 0
    error_message = "An empty configuration must install nothing."
  }
}
run "controller_defaults_and_overrides" {
  command = apply
  variables {
    enable_cert_manager = true
    enable_step_issuer  = true
    cert_manager        = { name = "certificates", namespace = "security", chart_version = "v1.21.2", values = ["replicaCount: 2"] }
    pki                 = { cert_manager_service_account = "certificates", cert_manager_namespace = "security" }
  }
  assert {
    condition     = keys(output.releases) == ["cert_manager", "step_issuer"] && output.releases.cert_manager.name == "certificates" && output.releases.cert_manager.namespace == "security"
    error_message = "Enable flags and release identity overrides must reach the wrapper."
  }
  assert {
    condition     = contains(yamldecode(local.integration_values.cert_manager[0]).approveSignerNames, "stepissuers.certmanager.step.sm/*") && yamldecode(local.integration_values.step_issuer[0]).certManager.serviceAccount.namespace == "security"
    error_message = "The approver and its RBAC binding must target the configured cert-manager identity."
  }
}
run "sidecar_without_cni" {
  command = apply
  variables {
    enable_istio = true
    istio        = { mode = "sidecar", cni_enabled = false }
  }
  assert {
    condition     = keys(output.releases) == ["istio_base", "istiod"] && yamldecode(local.integration_values.istiod[0]).cni.enabled == false
    error_message = "Sidecar mode may explicitly omit Istio CNI and must not create ztunnel."
  }
}
run "external_base_and_csr" {
  command = apply
  variables {
    enable_istio = true
    istio        = { mode = "ambient", manage_base = false, csr_address = "external-csr.security.svc:443" }
  }
  assert {
    condition     = keys(output.releases) == ["istio_cni", "istiod", "ztunnel"] && yamldecode(local.integration_values.istiod[1]).global.caAddress == "external-csr.security.svc:443"
    error_message = "External base and CSR dependencies must not create competing resources."
  }
}
run "reject_missing_mode" {
  command = plan
  variables { enable_istio = true }
  expect_failures = [var.istio]
}
run "reject_ambient_without_cni" {
  command = plan
  variables { istio = { mode = "ambient", cni_enabled = false } }
  expect_failures = [var.istio]
}
run "reject_missing_trust" {
  command = plan
  variables { enable_istio_csr = true }
  expect_failures = [var.pki]
}
run "reject_two_csr_owners" {
  command = plan
  variables {
    enable_istio_csr = true
    istio            = { csr_address = "external:443" }
    pki              = { issuer_name = "mesh", root_ca_config_map = "root" }
  }
  expect_failures = [var.istio]
}
