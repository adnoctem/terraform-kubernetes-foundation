output "issuers" {
  description = "Ready issuer references for the runtime stage."
  value       = module.configuration.step_issuers
}
output "trusted_roots" {
  description = "Public trust ConfigMaps for the runtime stage."
  value       = module.configuration.trusted_roots
}
