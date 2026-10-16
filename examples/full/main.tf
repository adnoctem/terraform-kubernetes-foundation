module "foundation" {
  source = "../.."

  enable_cilium              = true
  enable_cert_manager        = true
  enable_step_certificates   = true
  enable_step_issuer         = true
  enable_istio_base          = true
  enable_istio               = true
  enable_istio_csr           = true
  enable_argocd              = true
  cilium_istio_compatibility = true
  step_issuer_auto_approval  = true
  release_defaults = {
    atomic           = false
    create_namespace = true
    wait             = true
    timeout          = 900
    max_history      = 5
    cleanup_on_fail  = true
    wait_for_jobs    = true
    lint             = false
  }

  istio = {
    mode                    = var.istio_mode
    namespace               = "istio-system"
    chart_version           = "1.30.5"
    manage_base             = true
    cni_enabled             = true
    trust_domain            = "cluster.local"
    revision                = "default"
    ztunnel_service_account = "ztunnel"
    csr_address             = null # Mutually exclusive with enable_istio_csr.
  }
  pki = {
    issuer_name                  = var.issuer_name
    issuer_kind                  = "StepIssuer"
    issuer_group                 = "certmanager.step.sm"
    root_ca_config_map           = var.root_ca_config_map
    root_ca_key                  = "ca.pem"
    cert_manager_service_account = "cert-manager"
    cert_manager_namespace       = "cert-manager"
  }
  write_only_values = {
    argocd = [{ name = "configs.secret.extra.example-write-only", type = "string", value = var.write_only_value }]
  }

  cilium = merge(local.release_options, {
    name          = "cilium"
    chart         = "cilium"
    namespace     = "kube-system"
    repository    = "https://helm.cilium.io"
    chart_version = "1.20.2"
    values        = var.cilium_values
  })

  cert_manager = merge(local.release_options, {
    timeout       = null # Inherit the shared release_defaults timeout.
    name          = "cert-manager"
    chart         = "cert-manager"
    namespace     = "cert-manager"
    repository    = "oci://quay.io/jetstack/charts"
    chart_version = "v1.21.2"
  })

  step_certificates = merge(local.release_options, {
    name          = "step-certificates"
    chart         = "step-certificates"
    namespace     = "step-ca"
    repository    = "https://smallstep.github.io/helm-charts"
    chart_version = "1.30.1"
    values        = var.ca_values
  })

  step_issuer = merge(local.release_options, {
    name          = "step-issuer"
    chart         = "step-issuer"
    namespace     = "step-issuer"
    repository    = "https://smallstep.github.io/helm-charts"
    chart_version = "1.11.0"
  })

  istio_base = merge(local.release_options, {
    name          = "istio-base"
    chart         = "base"
    namespace     = "istio-system"
    repository    = "https://istio-release.storage.googleapis.com/charts"
    chart_version = "1.30.5"
  })

  istiod = merge(local.release_options, {
    name          = "istiod"
    chart         = "istiod"
    namespace     = "istio-system"
    repository    = "https://istio-release.storage.googleapis.com/charts"
    chart_version = "1.30.5"
  })

  istio_cni = merge(local.release_options, {
    name          = "istio-cni"
    chart         = "cni"
    namespace     = "istio-system"
    repository    = "https://istio-release.storage.googleapis.com/charts"
    chart_version = "1.30.5"
  })

  ztunnel = merge(local.release_options, {
    name          = "ztunnel"
    chart         = "ztunnel"
    namespace     = "istio-system"
    repository    = "https://istio-release.storage.googleapis.com/charts"
    chart_version = "1.30.5"
  })

  istio_csr = merge(local.release_options, {
    name          = "cert-manager-istio-csr"
    chart         = "cert-manager-istio-csr"
    namespace     = "cert-manager"
    repository    = "oci://quay.io/jetstack/charts"
    chart_version = "v0.18.0"
  })

  argocd = merge(local.release_options, {
    name            = "argocd"
    chart           = "argo-cd"
    namespace       = "argocd"
    repository      = "https://argoproj.github.io/argo-helm"
    chart_version   = "10.10.3"
    set_wo_revision = var.write_only_revision
    values          = [yamlencode({ global = { logging = { format = "json" } } })]
    values_object   = { server = { service = { type = "ClusterIP" } } }
    set             = [{ name = "server.replicas", type = "auto", value = "2" }]
    set_list        = [{ name = "server.extraArgs", value = ["--loglevel", "info"] }]
    set_sensitive   = [{ name = "configs.secret.extra.example-sensitive", type = "string", value = var.sensitive_value }]
    service_accounts = {
      server = {
        name        = "platform-server"
        create      = true
        annotations = { "example.com/team" = "platform" }
        labels      = { environment = "example" }
        pod_labels  = { "example.com/identity" = "platform" }
      }
    }
    service_account_paths = {
      server = {
        name        = ["server", "serviceAccount", "name"]
        create      = ["server", "serviceAccount", "create"]
        annotations = ["server", "serviceAccount", "annotations"]
        labels      = ["server", "serviceAccount", "labels"]
        pod_labels  = ["server", "podLabels"]
      }
    }
  })
}
