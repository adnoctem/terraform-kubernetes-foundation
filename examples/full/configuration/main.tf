module "configuration" {
  source = "../../../modules/configuration"

  namespaces = {
    public_trust = {
      name                             = "platform-trust"
      labels                           = { purpose = "public-trust" }
      annotations                      = { "example.com/owner" = "platform" }
      wait_for_default_service_account = false
      delete_timeout                   = "10m"
    }
  }
  trusted_roots = {
    mesh-root = {
      name        = "mesh-root"
      namespace   = "cert-manager"
      pem         = var.root_ca_pem
      key         = "ca.pem"
      labels      = { purpose = "mesh-trust" }
      annotations = { "example.com/owner" = "platform" }
      immutable   = false
      data        = { purpose = "Public root bundle" }
      binary_data = {}
    }
    public = {
      name        = "public-root"
      namespace   = "platform-trust"
      pem         = var.root_ca_pem
      key         = "ca.pem"
      labels      = { purpose = "public-trust" }
      annotations = {}
      immutable   = false
      data        = {}
      binary_data = { "notice.txt" = base64encode("Public certificates only") }
    }
  }
  step_issuers = {
    mesh = {
      name          = "mesh"
      kind          = "StepIssuer"
      namespace     = "istio-system"
      url           = var.ca_url
      ca_bundle_pem = var.root_ca_pem
      provisioner = {
        name = var.provisioner_name
        kid  = var.provisioner_kid
        password_ref = {
          name      = var.provisioner_secret
          key       = "password"
          namespace = null # A namespaced issuer uses its own namespace.
        }
      }
      labels      = { purpose = "mesh-issuance" }
      annotations = { "example.com/owner" = "platform" }
      wait_ready  = true
    }
    cluster = {
      name          = "cluster-ca"
      kind          = "StepClusterIssuer"
      namespace     = null # Cluster-scoped issuers have no namespace.
      url           = var.ca_url
      ca_bundle_pem = var.root_ca_pem
      provisioner = {
        name = var.provisioner_name
        kid  = var.provisioner_kid
        password_ref = {
          name      = var.provisioner_secret
          key       = "password"
          namespace = "istio-system"
        }
      }
      labels      = { purpose = "cluster-issuance" }
      annotations = {}
      wait_ready  = true
    }
  }
  argo_applications = var.bootstrap_application_spec == null ? {} : {
    bootstrap = {
      name        = "bootstrap"
      namespace   = "argocd"
      spec_yaml   = var.bootstrap_application_spec
      labels      = { purpose = "bootstrap" }
      annotations = { "example.com/owner" = "platform" }
      finalizers  = [] # Add deletion finalizers only when cascading deletion is intended.
      wait_fields = { "status.health.status" = "Healthy" }
    }
  }
  field_manager   = { name = "terraform-foundation", force_conflicts = false }
  computed_fields = ["metadata.annotations", "metadata.labels"]
  timeouts        = { create = "10m", update = "10m", delete = "10m" }
}
