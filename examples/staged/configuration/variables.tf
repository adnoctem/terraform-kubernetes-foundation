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
variable "ca_url" {
  type        = string
  default     = "https://step-certificates.step-ca.svc.cluster.local"
  description = "In-cluster Smallstep endpoint, or an external CA URL. Must match its serving certificate SANs."
}
variable "root_ca_pem" {
  type        = string
  description = "Public root bundle, independently verified against the intended CA."
}
variable "provisioner_name" {
  type        = string
  description = "Existing Smallstep JWK provisioner name."
}
variable "provisioner_kid" {
  type        = string
  description = "Existing provisioner's public key ID."
}
variable "provisioner_secret" {
  type        = string
  default     = "step-provisioner"
  description = "Existing Secret in istio-system containing the provisioner password under password."
}
variable "bootstrap_application_spec" {
  type        = string
  default     = null
  description = "Optional full Argo Application spec YAML. Omit to leave application bootstrapping elsewhere."
}
