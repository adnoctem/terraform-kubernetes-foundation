mock_provider "kubernetes" {}
run "empty_configuration" {
  command = plan
  module { source = "./modules/configuration" }
  assert {
    condition     = length(output.step_issuers) == 0 && length(output.argo_applications) == 0
    error_message = "Configuration resources must be opt-in."
  }
}
run "issuer_scopes_and_public_trust" {
  command = plan
  module { source = "./modules/configuration" }
  variables {
    namespaces    = { mesh = { name = "istio-system", labels = { purpose = "mesh" } } }
    trusted_roots = { root = { name = "mesh-root", namespace = "cert-manager", pem = "mock-public-ca" } }
    step_issuers = {
      mesh    = { namespace = "istio-system", url = "https://ca.example.com", ca_bundle_pem = "mock-public-ca", provisioner = { name = "mesh", kid = "public-id", password_ref = { name = "provisioner", key = "password" } } }
      cluster = { kind = "StepClusterIssuer", url = "https://ca.example.com", ca_bundle_pem = "mock-public-ca", provisioner = { name = "cluster", kid = "public-id", password_ref = { name = "provisioner", namespace = "step-issuer", key = "password" } } }
    }
  }
  assert {
    condition     = kubernetes_manifest.step_issuer["mesh"].manifest.spec.caBundle == base64encode("mock-public-ca") && kubernetes_manifest.step_issuer["mesh"].manifest.metadata.namespace == "istio-system" && !contains(keys(kubernetes_manifest.step_issuer["cluster"].manifest.metadata), "namespace")
    error_message = "Public trust must be encoded once and issuer scopes must match the CRD."
  }
  assert {
    condition     = kubernetes_manifest.step_issuer["cluster"].manifest.spec.provisioner.passwordRef.namespace == "step-issuer" && kubernetes_config_map_v1.trusted_root["root"].data["ca.pem"] == "mock-public-ca" # gitleaks:allow -- namespace and public test bundle, no password value
    error_message = "Secret references and public ConfigMaps must be preserved without reading secret contents."
  }
}
run "bootstrap_application" {
  command = plan
  module { source = "./modules/configuration" }
  variables {
    argo_applications = {
      platform = { spec_yaml = "project: default\nsource:\n  repoURL: https://github.com/example/gitops.git\n  path: clusters/dev\ndestination:\n  server: https://kubernetes.default.svc\n  namespace: default\n" }
    }
  }
  assert {
    condition     = kubernetes_manifest.argo_application["platform"].manifest.spec.source.path == "clusters/dev" && length(kubernetes_manifest.argo_application["platform"].manifest.metadata.finalizers) == 0
    error_message = "Application specs must remain configurable without enabling cascading deletion implicitly."
  }
}
run "reject_cluster_issuer_namespace" {
  command = plan
  module { source = "./modules/configuration" }
  variables {
    step_issuers = { invalid = { kind = "StepClusterIssuer", namespace = "invalid", url = "https://ca.example.com", ca_bundle_pem = "public", provisioner = { name = "mesh", kid = "id", password_ref = { name = "secret", key = "password" } } } }
  }
  expect_failures = [var.step_issuers]
}
