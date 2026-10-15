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

run "shared_defaults_and_explicit_false" {
  command = apply
  variables {
    enable_argocd       = true
    enable_cert_manager = true
    release_defaults    = { timeout = 900, wait = true, atomic = true, max_history = 8, cleanup_on_fail = true }
    argocd              = { timeout = 1200, wait = false, atomic = false, max_history = 0, cleanup_on_fail = false }
    cert_manager        = { timeout = null }
  }
  assert {
    condition     = local.effective_release_defaults.argocd.timeout == 1200 && local.effective_release_defaults.argocd.wait == false && local.effective_release_defaults.argocd.atomic == false && local.effective_release_defaults.argocd.max_history == 0 && local.effective_release_defaults.argocd.cleanup_on_fail == false && local.effective_release_defaults.cert_manager.timeout == 900
    error_message = "Component settings must override shared defaults, including false and zero; null must inherit."
  }
}
run "identity_relationships" {
  command = apply
  variables {
    enable_cert_manager = true
    enable_step_issuer  = true
    enable_istio        = true
    enable_istio_csr    = true
    istio               = { mode = "ambient" }
    pki                 = { issuer_name = "mesh", root_ca_config_map = "root" }
    cert_manager        = { namespace = "security", service_accounts = { controller = { name = "certificates" } } }
    ztunnel             = { service_accounts = { default = { name = "node-proxy" } } }
  }
  assert {
    condition     = yamldecode(local.integration_values.step_issuer[0]).certManager.serviceAccount.name == "certificates" && yamldecode(local.integration_values.step_issuer[0]).certManager.serviceAccount.namespace == "security" && yamldecode(local.integration_values.istio_csr[0]).app.server.caTrustedNodeAccounts == "istio-system/node-proxy"
    error_message = "Derived RBAC and ambient trust must follow configured service-account identities."
  }
}
run "custom_mapping" {
  command = plan
  variables {
    enable_argocd = true
    argocd        = { service_account_paths = { server = { annotations = ["custom", "annotations"] } } }
  }
  assert {
    condition     = local.service_account_paths.argocd.server.annotations == tolist(["custom", "annotations"]) && tolist(local.service_account_paths.argocd.server.name) == tolist(["server", "serviceAccount", "name"])
    error_message = "An explicit field mapping must override that field while preserving the role's other mappings."
  }
}
run "reject_invalid_shared_defaults" {
  command = plan
  variables { release_defaults = { timeout = 0 } }
  expect_failures = [var.release_defaults]
}
run "reject_step_issuer_existing_account" {
  command = plan
  variables { step_issuer = { service_accounts = { default = { name = "external", create = false } } } }
  expect_failures = [var.step_issuer]
}

run "derived_chart_account_name" {
  command = plan
  variables {
    enable_cert_manager = true
    enable_step_issuer  = true
    cert_manager        = { name = "certificates" }
  }
  assert {
    condition     = local.cert_manager_account == "certificates-cert-manager"
    error_message = "A renamed release must follow the chart's fullname helper when deriving the approval account."
  }
}
run "existing_default_account" {
  command = plan
  variables {
    enable_cert_manager = true
    enable_step_issuer  = true
    cert_manager        = { service_accounts = { controller = { create = false } } }
  }
  assert {
    condition     = local.cert_manager_account == "default"
    error_message = "With creation disabled and no name, the chart consumes the namespace's default account."
  }
}
