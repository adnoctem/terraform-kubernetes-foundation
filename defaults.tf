locals {
  components = {
    cilium            = var.cilium
    cert_manager      = var.cert_manager
    step_certificates = var.step_certificates
    step_issuer       = var.step_issuer
    istio_base        = var.istio_base
    istiod            = var.istiod
    istio_cni         = var.istio_cni
    ztunnel           = var.ztunnel
    istio_csr         = var.istio_csr
    argocd            = var.argocd
  }
  effective_release_defaults = {
    for component, settings in local.components : component => merge(var.release_defaults, {
      for key, value in settings : key => value
      if contains(keys(var.release_defaults), key) && value != null
    })
  }
  # Mappings are verified against the pinned charts. A missing field is unsupported.
  chart_service_account_paths = {
    cilium = {
      agent = {
        name        = ["serviceAccounts", "cilium", "name"]
        create      = ["serviceAccounts", "cilium", "create"]
        annotations = ["serviceAccounts", "cilium", "annotations"]
        pod_labels  = ["podLabels"]
      }
      operator = {
        name        = ["serviceAccounts", "operator", "name"]
        create      = ["serviceAccounts", "operator", "create"]
        annotations = ["serviceAccounts", "operator", "annotations"]
        pod_labels  = ["operator", "podLabels"]
      }
      relay = {
        name        = ["serviceAccounts", "relay", "name"]
        create      = ["serviceAccounts", "relay", "create"]
        annotations = ["serviceAccounts", "relay", "annotations"]
        pod_labels  = ["hubble", "relay", "podLabels"]
      }
      ui = {
        name        = ["serviceAccounts", "ui", "name"]
        create      = ["serviceAccounts", "ui", "create"]
        annotations = ["serviceAccounts", "ui", "annotations"]
        pod_labels  = ["hubble", "ui", "podLabels"]
      }
    }
    cert_manager = {
      controller = {
        name        = ["serviceAccount", "name"]
        create      = ["serviceAccount", "create"]
        annotations = ["serviceAccount", "annotations"]
        labels      = ["serviceAccount", "labels"]
        pod_labels  = ["podLabels"]
      }
      webhook = {
        name        = ["webhook", "serviceAccount", "name"]
        create      = ["webhook", "serviceAccount", "create"]
        annotations = ["webhook", "serviceAccount", "annotations"]
        labels      = ["webhook", "serviceAccount", "labels"]
        pod_labels  = ["webhook", "podLabels"]
      }
      cainjector = {
        name        = ["cainjector", "serviceAccount", "name"]
        create      = ["cainjector", "serviceAccount", "create"]
        annotations = ["cainjector", "serviceAccount", "annotations"]
        labels      = ["cainjector", "serviceAccount", "labels"]
        pod_labels  = ["cainjector", "podLabels"]
      }
      startupapicheck = {
        name        = ["startupapicheck", "serviceAccount", "name"]
        create      = ["startupapicheck", "serviceAccount", "create"]
        annotations = ["startupapicheck", "serviceAccount", "annotations"]
        labels      = ["startupapicheck", "serviceAccount", "labels"]
        pod_labels  = ["startupapicheck", "podLabels"]
      }
    }
    step_certificates = {
      default = {
        name        = ["serviceaccount", "name"]
        create      = ["serviceaccount", "create"]
        annotations = ["serviceaccount", "annotations"]
        labels      = ["serviceaccount", "labels"]
        pod_labels  = ["podExtraLabels"]
      }
    }
    step_issuer = {
      default = {
        name        = ["serviceAccount", "name"]
        create      = ["serviceAccount", "create"]
        annotations = ["serviceAccount", "annotations"]
      }
    }
    istio_base = {
    }
    istiod = {
      default = {
        annotations = ["serviceAccountAnnotations"]
        pod_labels  = ["podLabels"]
      }
    }
    istio_cni = {
      default = {
        pod_labels = ["podLabels"]
      }
    }
    ztunnel = {
      default = {
        name        = ["resourceName"]
        annotations = ["annotations"]
        labels      = ["labels"]
        pod_labels  = ["podLabels"]
      }
    }
    istio_csr = {
      default = {
        pod_labels = ["podLabels"]
      }
    }
    argocd = {
      controller = {
        name        = ["controller", "serviceAccount", "name"]
        create      = ["controller", "serviceAccount", "create"]
        annotations = ["controller", "serviceAccount", "annotations"]
        labels      = ["controller", "serviceAccount", "labels"]
        pod_labels  = ["controller", "podLabels"]
      }
      server = {
        name        = ["server", "serviceAccount", "name"]
        create      = ["server", "serviceAccount", "create"]
        annotations = ["server", "serviceAccount", "annotations"]
        labels      = ["server", "serviceAccount", "labels"]
        pod_labels  = ["server", "podLabels"]
      }
      repo_server = {
        name        = ["repoServer", "serviceAccount", "name"]
        create      = ["repoServer", "serviceAccount", "create"]
        annotations = ["repoServer", "serviceAccount", "annotations"]
        labels      = ["repoServer", "serviceAccount", "labels"]
        pod_labels  = ["repoServer", "podLabels"]
      }
      application_set = {
        name        = ["applicationSet", "serviceAccount", "name"]
        create      = ["applicationSet", "serviceAccount", "create"]
        annotations = ["applicationSet", "serviceAccount", "annotations"]
        labels      = ["applicationSet", "serviceAccount", "labels"]
        pod_labels  = ["applicationSet", "podLabels"]
      }
      notifications = {
        name        = ["notifications", "serviceAccount", "name"]
        create      = ["notifications", "serviceAccount", "create"]
        annotations = ["notifications", "serviceAccount", "annotations"]
        labels      = ["notifications", "serviceAccount", "labels"]
        pod_labels  = ["notifications", "podLabels"]
      }
      dex = {
        name        = ["dex", "serviceAccount", "name"]
        create      = ["dex", "serviceAccount", "create"]
        annotations = ["dex", "serviceAccount", "annotations"]
        pod_labels  = ["dex", "podLabels"]
      }
      redis = {
        name        = ["redis", "serviceAccount", "name"]
        create      = ["redis", "serviceAccount", "create"]
        annotations = ["redis", "serviceAccount", "annotations"]
        pod_labels  = ["redis", "podLabels"]
      }
      redis_secret_init = {
        name        = ["redisSecretInit", "serviceAccount", "name"]
        create      = ["redisSecretInit", "serviceAccount", "create"]
        annotations = ["redisSecretInit", "serviceAccount", "annotations"]
        pod_labels  = ["redisSecretInit", "podLabels"]
      }
      commit_server = {
        name        = ["commitServer", "serviceAccount", "name"]
        create      = ["commitServer", "serviceAccount", "create"]
        annotations = ["commitServer", "serviceAccount", "annotations"]
        labels      = ["commitServer", "serviceAccount", "labels"]
        pod_labels  = ["commitServer", "podLabels"]
      }
    }
  }
  service_account_paths = {
    for component, settings in local.components : component => {
      for role in setunion(toset(keys(local.chart_service_account_paths[component])), toset(keys(settings.service_account_paths))) : role => merge(
        lookup(local.chart_service_account_paths[component], role, {}),
        lookup(settings.service_account_paths, role, {})
      )
    }
  }
  # Match the pinned chart's fullname/account helpers when no explicit name is supplied.
  cert_manager_chart_account = try(var.cert_manager.service_accounts.controller.create == false, false) ? "default" : trimsuffix(substr(strcontains(var.cert_manager.name, "cert-manager") ? var.cert_manager.name : "${var.cert_manager.name}-cert-manager", 0, 63), "-")
  cert_manager_account       = coalesce(var.pki.cert_manager_service_account, try(var.cert_manager.service_accounts.controller.name, null), local.cert_manager_chart_account)
  cert_manager_namespace     = coalesce(var.pki.cert_manager_namespace, var.cert_manager.namespace)
  ztunnel_account            = coalesce(try(var.ztunnel.service_accounts.default.name, null), var.istio.ztunnel_service_account)
}
