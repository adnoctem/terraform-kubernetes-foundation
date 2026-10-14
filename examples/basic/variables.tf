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
