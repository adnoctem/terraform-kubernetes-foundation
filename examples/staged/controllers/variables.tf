variable "kubeconfig" {
  type        = string
  default     = "~/.kube/config"
  description = "Path to the caller's kubeconfig."
}
variable "kube_context" {
  type        = string
  default     = null
  description = "Optional kubeconfig context."
}
variable "cilium_values" {
  type        = list(string)
  description = "Required cluster-specific Cilium YAML: IPAM, routing, API server access, and kube-proxy decisions."
}
variable "in_cluster_ca" {
  type        = bool
  default     = true
  description = "Run step-certificates using pre-provisioned signing material; false uses an external CA."
}
variable "ca_values" {
  type        = list(string)
  default     = []
  description = "Non-secret step-certificates chart settings, such as storage class and service configuration."
}
