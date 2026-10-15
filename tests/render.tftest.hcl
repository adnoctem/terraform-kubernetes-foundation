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

  release_defaults = { timeout = 900 }
  cilium = {
    values_object = { "hubble" = { "relay" = { "enabled" = true }, "ui" = { "enabled" = true } } }
    service_accounts = {
      agent = {
        name        = "foundation-test-cilium-agent-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cilium-agent-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cilium-agent-pod-labels" }
      }
      operator = {
        name        = "foundation-test-cilium-operator-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cilium-operator-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cilium-operator-pod-labels" }
      }
      relay = {
        name        = "foundation-test-cilium-relay-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cilium-relay-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cilium-relay-pod-labels" }
      }
      ui = {
        name        = "foundation-test-cilium-ui-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cilium-ui-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cilium-ui-pod-labels" }
      }
    }
  }
  cert_manager = {
    values_object = { "replicaCount" = 2 }
    service_accounts = {
      controller = {
        name        = "foundation-test-cert-manager-controller-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cert-manager-controller-annotations" }
        labels      = { "example.com/labels" = "foundation-test-cert-manager-controller-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cert-manager-controller-pod-labels" }
      }
      webhook = {
        name        = "foundation-test-cert-manager-webhook-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cert-manager-webhook-annotations" }
        labels      = { "example.com/labels" = "foundation-test-cert-manager-webhook-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cert-manager-webhook-pod-labels" }
      }
      cainjector = {
        name        = "foundation-test-cert-manager-cainjector-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cert-manager-cainjector-annotations" }
        labels      = { "example.com/labels" = "foundation-test-cert-manager-cainjector-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cert-manager-cainjector-pod-labels" }
      }
      startupapicheck = {
        name        = "foundation-test-cert-manager-startupapicheck-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-cert-manager-startupapicheck-annotations" }
        labels      = { "example.com/labels" = "foundation-test-cert-manager-startupapicheck-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-cert-manager-startupapicheck-pod-labels" }
      }
    }
  }
  step_certificates = {
    service_accounts = {
      default = {
        name        = "foundation-test-step-certificates-default-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-step-certificates-default-annotations" }
        labels      = { "example.com/labels" = "foundation-test-step-certificates-default-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-step-certificates-default-pod-labels" }
      }
    }
  }
  step_issuer = {
    service_accounts = {
      default = {
        name        = "foundation-test-step-issuer-default-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-step-issuer-default-annotations" }
      }
    }
  }
  istiod = {
    service_accounts = {
      default = {
        annotations = { "example.com/annotations" = "foundation-test-istiod-default-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-istiod-default-pod-labels" }
      }
    }
  }
  istio_cni = {
    service_accounts = {
      default = {
        pod_labels = { "example.com/pod-labels" = "foundation-test-istio-cni-default-pod-labels" }
      }
    }
  }
  ztunnel = {
    service_accounts = {
      default = {
        name        = "foundation-test-ztunnel-default-name"
        annotations = { "example.com/annotations" = "foundation-test-ztunnel-default-annotations" }
        labels      = { "example.com/labels" = "foundation-test-ztunnel-default-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-ztunnel-default-pod-labels" }
      }
    }
  }
  istio_csr = {
    service_accounts = {
      default = {
        pod_labels = { "example.com/pod-labels" = "foundation-test-istio-csr-default-pod-labels" }
      }
    }
  }
  argocd = {
    values_object = { "commitServer" = { "enabled" = true } }
    service_accounts = {
      controller = {
        name        = "foundation-test-argocd-controller-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-controller-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-controller-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-controller-pod-labels" }
      }
      server = {
        name        = "foundation-test-argocd-server-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-server-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-server-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-server-pod-labels" }
      }
      repo_server = {
        name        = "foundation-test-argocd-repo-server-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-repo-server-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-repo-server-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-repo-server-pod-labels" }
      }
      application_set = {
        name        = "foundation-test-argocd-application-set-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-application-set-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-application-set-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-application-set-pod-labels" }
      }
      notifications = {
        name        = "foundation-test-argocd-notifications-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-notifications-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-notifications-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-notifications-pod-labels" }
      }
      dex = {
        name        = "foundation-test-argocd-dex-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-dex-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-dex-pod-labels" }
      }
      redis = {
        name        = "foundation-test-argocd-redis-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-redis-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-redis-pod-labels" }
      }
      redis_secret_init = {
        name        = "foundation-test-argocd-redis-secret-init-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-redis-secret-init-annotations" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-redis-secret-init-pod-labels" }
      }
      commit_server = {
        name        = "foundation-test-argocd-commit-server-name"
        create      = true
        annotations = { "example.com/annotations" = "foundation-test-argocd-commit-server-annotations" }
        labels      = { "example.com/labels" = "foundation-test-argocd-commit-server-labels" }
        pod_labels  = { "example.com/pod-labels" = "foundation-test-argocd-commit-server-pod-labels" }
      }
    }
  }

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
    condition     = yamldecode(local.integration_values.istio_csr[0]).app.server.caTrustedNodeAccounts == "istio-system/foundation-test-ztunnel-default-name" && yamldecode(local.integration_values.ztunnel[0]).caAddress == "cert-manager-istio-csr.cert-manager.svc:443"
    error_message = "Ambient CSR authentication and the node proxy must share the configured identity and endpoint."
  }
}
