output "namespaces" {
  value       = { for key, namespace in kubernetes_namespace_v1.current : key => namespace.metadata[0].name }
  description = "Managed namespace names."
}
output "trusted_roots" {
  value       = { for key, root in kubernetes_config_map_v1.trusted_root : key => { name = root.metadata[0].name, namespace = root.metadata[0].namespace, key = var.trusted_roots[key].key } }
  description = "Trusted-root ConfigMap references for the next stage."
}
output "step_issuers" {
  value       = { for key, issuer in kubernetes_manifest.step_issuer : key => { name = issuer.manifest.metadata.name, namespace = try(issuer.manifest.metadata.namespace, null), kind = issuer.manifest.kind, group = "certmanager.step.sm" } }
  description = "Issuer references. Output depends on configured readiness checks."
}
output "argo_applications" {
  value       = { for key, app in kubernetes_manifest.argo_application : key => { name = app.manifest.metadata.name, namespace = app.manifest.metadata.namespace } }
  description = "Terraform-owned bootstrap Application references."
}
