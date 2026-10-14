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
variable "istio_mode" {
  type        = string
  description = "Explicitly select sidecar or ambient."
  validation {
    condition     = contains(["sidecar", "ambient"], var.istio_mode)
    error_message = "Choose sidecar or ambient."
  }
}
