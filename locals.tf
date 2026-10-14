locals {
  manage_istio_base = var.enable_istio_base || (var.enable_istio && var.istio.manage_base)
  istiod_namespace  = coalesce(var.istiod.namespace, var.istio.namespace)
  ztunnel_namespace = coalesce(var.ztunnel.namespace, var.istio.namespace)
  csr_address       = var.enable_istio_csr ? "${var.istio_csr.name}.${var.istio_csr.namespace}.svc:443" : var.istio.csr_address
  # Serialized documents keep heterogeneous chart values intact and let Helm merge them.
  integration_values = {
    cilium = var.cilium_istio_compatibility || var.enable_istio ? [yamlencode({
      socketLB = { hostNamespaceOnly = true }
      cni      = { exclusive = false }
    })] : []
    cert_manager = [yamlencode(merge({ crds = { enabled = true } }, var.enable_step_issuer || var.step_issuer_auto_approval ? {
      approveSignerNames = ["issuers.cert-manager.io/*", "clusterissuers.cert-manager.io/*", "stepissuers.certmanager.step.sm/*", "stepclusterissuers.certmanager.step.sm/*"]
    } : {}))]
    step_certificates = [yamlencode({
      bootstrap       = { enabled = false, configmaps = false, secrets = false }
      existingSecrets = { enabled = true, ca = true }
    })]
    step_issuer = [yamlencode({
      serviceAccount = { create = true }
      certManager    = { serviceAccount = { name = var.pki.cert_manager_service_account, namespace = var.pki.cert_manager_namespace } }
    })]
    istio_base = [yamlencode({ defaultRevision = var.istio.revision })]
    istiod = concat([yamlencode({
      profile    = var.istio.mode == "ambient" ? "ambient" : ""
      revision   = var.istio.revision == "default" ? "" : var.istio.revision
      cni        = { enabled = var.istio.cni_enabled }
      meshConfig = { trustDomain = var.istio.trust_domain }
      })], local.csr_address == null ? [] : [yamlencode({
      global = { caAddress = local.csr_address, pilotCertProvider = "custom" }
      env    = { ENABLE_CA_SERVER = "false" }
    })])
    istio_cni = [yamlencode({ profile = var.istio.mode == "ambient" ? "ambient" : "" })]
    ztunnel = [yamlencode(merge({
      env            = { TRUST_DOMAIN = var.istio.trust_domain }
      resourceName   = var.istio.ztunnel_service_account
      istioNamespace = local.istiod_namespace
      revision       = var.istio.revision == "default" ? "" : var.istio.revision
    }, local.csr_address == null ? {} : { caAddress = local.csr_address }))]
    istio_csr = [yamlencode({
      nameOverride = var.istio_csr.name
      app = {
        certmanager = {
          namespace = local.istiod_namespace
          issuer    = { enabled = true, name = var.pki.issuer_name, kind = var.pki.issuer_kind, group = var.pki.issuer_group }
        }
        tls = {
          trustDomain         = var.istio.trust_domain
          rootCAFile          = "/var/run/istio-csr-root/ca.pem"
          certificateDNSNames = ["${var.istio_csr.name}.${var.istio_csr.namespace}.svc"]
        }
        istio      = { namespace = local.istiod_namespace, revisions = [var.istio.revision] }
        controller = { leaderElectionNamespace = local.istiod_namespace }
        server     = { caTrustedNodeAccounts = var.istio.mode == "ambient" ? "${local.ztunnel_namespace}/${var.istio.ztunnel_service_account}" : "" }
      }
      volumes      = [{ name = "trusted-root", configMap = { name = var.pki.root_ca_config_map, items = [{ key = var.pki.root_ca_key, path = "ca.pem" }] } }]
      volumeMounts = [{ name = "trusted-root", mountPath = "/var/run/istio-csr-root", readOnly = true }]
    })]
    argocd = []
  }
}
