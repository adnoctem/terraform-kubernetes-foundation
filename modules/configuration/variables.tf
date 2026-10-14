variable "namespaces" {
  type = map(object({
    name                             = optional(string)
    labels                           = optional(map(string), {})
    annotations                      = optional(map(string), {})
    wait_for_default_service_account = optional(bool, false)
    delete_timeout                   = optional(string)
  }))
  default     = {}
  nullable    = false
  description = "Optional namespaces owned by this module. Omit namespaces owned by Helm or another configuration. Names default to map keys."
}

variable "trusted_roots" {
  type = map(object({
    name        = optional(string)
    namespace   = string
    pem         = string
    key         = optional(string, "ca.pem")
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
    immutable   = optional(bool, false)
    data        = optional(map(string), {})
    binary_data = optional(map(string), {})
  }))
  default     = {}
  nullable    = false
  description = "Public CA bundles in ConfigMaps. PEM is stored under key, overriding that key in data. Never pass a private key."
}

variable "step_issuers" {
  type = map(object({
    name          = optional(string)
    kind          = optional(string, "StepIssuer")
    namespace     = optional(string)
    url           = string
    ca_bundle_pem = string
    provisioner = object({
      name         = string
      kid          = string
      password_ref = object({ name = string, key = string, namespace = optional(string) })
    })
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
    wait_ready  = optional(bool, true)
  }))
  default     = {}
  nullable    = false
  description = "StepIssuer/StepClusterIssuer resources. Their CRDs must exist before planning. Referenced provisioner Secrets must already exist. Public CA PEM is encoded once as required by the API."
  validation {
    condition     = alltrue([for issuer in var.step_issuers : contains(["StepIssuer", "StepClusterIssuer"], issuer.kind)])
    error_message = "Issuer kind must be StepIssuer or StepClusterIssuer."
  }
  validation {
    condition     = alltrue([for issuer in var.step_issuers : issuer.kind == "StepIssuer" ? issuer.namespace != null && issuer.provisioner.password_ref.namespace == null : issuer.namespace == null && issuer.provisioner.password_ref.namespace != null])
    error_message = "StepIssuer requires namespace and a same-namespace password reference; StepClusterIssuer omits namespace and requires password_ref.namespace."
  }
}

variable "argo_applications" {
  type = map(object({
    name        = optional(string)
    namespace   = optional(string, "argocd")
    spec_yaml   = string
    labels      = optional(map(string), {})
    annotations = optional(map(string), {})
    finalizers  = optional(list(string), [])
    wait_fields = optional(map(string), {})
  }))
  default     = {}
  nullable    = false
  description = "Explicitly Terraform-owned Argo bootstrap Applications. Argo CRDs must already exist. spec_yaml permits the full Application spec, including multi-source configurations. Avoid having Argo manage these same objects."
  validation {
    condition     = alltrue([for app in var.argo_applications : can(keys(yamldecode(app.spec_yaml)))])
    error_message = "Application spec_yaml must decode to a YAML mapping."
  }
}

variable "field_manager" {
  type        = object({ name = optional(string, "terraform-foundation"), force_conflicts = optional(bool, false) })
  default     = {}
  nullable    = false
  description = "Server-side apply ownership for custom resources. Force-conflicts is opt-in."
}

variable "computed_fields" {
  type        = list(string)
  default     = ["metadata.annotations", "metadata.labels"]
  nullable    = false
  description = "Manifest fields Kubernetes may modify. Extend for admission-controller mutations when necessary."
}

variable "timeouts" {
  type        = object({ create = optional(string, "10m"), update = optional(string, "10m"), delete = optional(string, "10m") })
  default     = {}
  nullable    = false
  description = "Custom resource operation and readiness timeouts."
}
