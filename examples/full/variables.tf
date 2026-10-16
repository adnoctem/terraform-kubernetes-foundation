variable "kubeconfig" {
  description = "Path to the caller's kubeconfig."
  type        = string
  default     = "~/.kube/config"
}

variable "repository_auth" {
  description = "Optional repository credentials and TLS files; leave empty for the public repositories."
  type = object({
    ca_file   = optional(string)
    cert_file = optional(string)
    key_file  = optional(string)
    username  = optional(string)
    password  = optional(string)
  })
  default   = {}
  sensitive = true
}

variable "keyring" {
  description = "Optional provenance keyring path. Also enable verify only for a chart with a matching provenance signature."
  type        = string
  default     = null
}

variable "sensitive_value" {
  description = "Example ordinary sensitive override; this value is retained in Terraform state."
  type        = string
  sensitive   = true
}

variable "write_only_value" {
  description = "Example ephemeral override; Helm and the chart may still store this value in Kubernetes."
  type        = string
  sensitive   = true
  ephemeral   = true
}

variable "write_only_revision" {
  description = "Increment when write_only_value changes."
  type        = number
  default     = 1
}

variable "istio_mode" {
  description = "Select sidecar or ambient for this cluster."
  type        = string
  validation {
    condition     = contains(["sidecar", "ambient"], var.istio_mode)
    error_message = "Choose sidecar or ambient."
  }
}

variable "cilium_values" {
  description = "Cluster-specific networking YAML: routing, IPAM, API endpoint, and kube-proxy settings."
  type        = list(string)
}

variable "ca_values" {
  description = "CA chart YAML referencing existing configuration and signing material."
  type        = list(string)
  default     = []
}

variable "issuer_name" {
  description = "Existing Ready StepIssuer in istio-system."
  type        = string
}

variable "root_ca_config_map" {
  description = "Existing public root bundle ConfigMap in cert-manager, with a ca.pem key."
  type        = string
}
