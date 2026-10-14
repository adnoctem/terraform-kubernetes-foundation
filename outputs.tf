output "releases" {
  description = "Managed release identities keyed by component. References carry release completion dependencies."
  value = merge(
    { for release in module.cilium : "cilium" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.cert_manager : "cert_manager" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.step_certificates : "step_certificates" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.step_issuer : "step_issuer" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.istio_base : "istio_base" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.istio_csr : "istio_csr" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.istio_cni_sidecar : "istio_cni" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.istiod : "istiod" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.istio_cni_ambient : "istio_cni" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.ztunnel : "ztunnel" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
    { for release in module.argocd : "argocd" => { name = release.name, namespace = release.namespace, chart = release.chart, chart_version = release.chart_version, status = release.status } },
  )
}
