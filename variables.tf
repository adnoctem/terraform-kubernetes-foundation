variable "enable_cilium" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage cilium. False removes resources previously managed by this invocation."
}

variable "enable_cert_manager" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage cert manager. False removes resources previously managed by this invocation."
}

variable "enable_step_certificates" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage step certificates. False removes resources previously managed by this invocation."
}

variable "enable_step_issuer" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage step issuer. False removes resources previously managed by this invocation."
}

variable "enable_istio" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage istio. False removes resources previously managed by this invocation."
}

variable "enable_istio_base" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage istio base. False removes resources previously managed by this invocation."
}

variable "enable_istio_csr" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage istio csr. False removes resources previously managed by this invocation."
}

variable "enable_argocd" {
  type        = bool
  default     = false
  nullable    = false
  description = "Manage argocd. False removes resources previously managed by this invocation."
}

variable "cilium" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "cilium")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "cilium")
    namespace                  = optional(string, "kube-system")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://helm.cilium.io")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=helm depName=cilium registryUrl=https://helm.cilium.io
    chart_version = optional(string, "1.20.2")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "cilium Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "cert_manager" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "cert-manager")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "cert-manager")
    namespace                  = optional(string, "cert-manager")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "oci://quay.io/jetstack/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=docker depName=quay.io/jetstack/charts/cert-manager
    chart_version = optional(string, "v1.21.2")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "cert manager Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "step_certificates" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "step-certificates")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "step-certificates")
    namespace                  = optional(string, "step-ca")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://smallstep.github.io/helm-charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=helm depName=step-certificates registryUrl=https://smallstep.github.io/helm-charts
    chart_version = optional(string, "1.30.1")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "step certificates Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "step_issuer" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "step-issuer")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "step-issuer")
    namespace                  = optional(string, "step-issuer")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://smallstep.github.io/helm-charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=helm depName=step-issuer registryUrl=https://smallstep.github.io/helm-charts
    chart_version = optional(string, "1.11.0")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "step issuer Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "istio_base" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "base")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "istio-base")
    namespace                  = optional(string)
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://istio-release.storage.googleapis.com/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    chart_version   = optional(string)
    wait            = optional(bool, true)
    wait_for_jobs   = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "istio base Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "istiod" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "istiod")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "istiod")
    namespace                  = optional(string)
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://istio-release.storage.googleapis.com/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    chart_version   = optional(string)
    wait            = optional(bool, true)
    wait_for_jobs   = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "istiod Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "istio_cni" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "cni")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "istio-cni")
    namespace                  = optional(string)
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://istio-release.storage.googleapis.com/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    chart_version   = optional(string)
    wait            = optional(bool, true)
    wait_for_jobs   = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "istio cni Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "ztunnel" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "ztunnel")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "ztunnel")
    namespace                  = optional(string)
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://istio-release.storage.googleapis.com/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    chart_version   = optional(string)
    wait            = optional(bool, true)
    wait_for_jobs   = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "ztunnel Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "istio_csr" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "cert-manager-istio-csr")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "cert-manager-istio-csr")
    namespace                  = optional(string, "cert-manager")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "oci://quay.io/jetstack/charts")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=docker depName=quay.io/jetstack/charts/cert-manager-istio-csr
    chart_version = optional(string, "v0.18.0")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "istio csr Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "argocd" {
  type = object({
    atomic                     = optional(bool, false)
    chart                      = optional(string, "argo-cd")
    cleanup_on_fail            = optional(bool)
    create_namespace           = optional(bool, true)
    dependency_update          = optional(bool)
    description                = optional(string)
    devel                      = optional(bool)
    disable_crd_hooks          = optional(bool)
    disable_openapi_validation = optional(bool)
    disable_webhooks           = optional(bool)
    force_update               = optional(bool)
    keyring                    = optional(string)
    lint                       = optional(bool)
    max_history                = optional(number, 10)
    name                       = optional(string, "argocd")
    namespace                  = optional(string, "argocd")
    pass_credentials           = optional(bool)
    postrender = optional(object({
      args        = optional(list(string))
      binary_path = string
    }))
    recreate_pods         = optional(bool)
    render_subchart_notes = optional(bool)
    replace               = optional(bool)
    repository            = optional(string, "https://argoproj.github.io/argo-helm")
    repository_ca_file    = optional(string)
    repository_cert_file  = optional(string)
    repository_key_file   = optional(string)
    repository_password   = optional(string)
    repository_username   = optional(string)
    reset_values          = optional(bool)
    reuse_values          = optional(bool)
    set = optional(list(object({
      name  = string
      type  = optional(string)
      value = optional(string)
    })), [])
    set_list = optional(list(object({
      name  = string
      value = list(string)
    })), [])
    set_sensitive = optional(list(object({
      name  = string
      type  = optional(string)
      value = string
    })), [])
    set_wo_revision = optional(number)
    skip_crds       = optional(bool)
    take_ownership  = optional(bool)
    timeout         = optional(number, 600)
    timeouts = optional(object({
      create = optional(string)
      delete = optional(string)
      read   = optional(string)
      update = optional(string)
    }))
    upgrade_install = optional(bool)
    values          = optional(list(string), [])
    verify          = optional(bool)
    # renovate: datasource=helm depName=argo-cd registryUrl=https://argoproj.github.io/argo-helm
    chart_version = optional(string, "10.10.3")
    wait          = optional(bool, true)
    wait_for_jobs = optional(bool)
  })
  default     = {}
  nullable    = false
  description = "argocd Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults."
}

variable "istio" {
  type = object({
    mode      = optional(string)
    namespace = optional(string, "istio-system")
    # renovate: datasource=helm depName=istiod registryUrl=https://istio-release.storage.googleapis.com/charts
    chart_version           = optional(string, "1.30.5")
    manage_base             = optional(bool, true)
    cni_enabled             = optional(bool, true)
    trust_domain            = optional(string, "cluster.local")
    revision                = optional(string, "default")
    ztunnel_service_account = optional(string, "ztunnel")
    csr_address             = optional(string)
  })
  default     = {}
  nullable    = false
  description = "Coordinated Istio settings. Select sidecar or ambient explicitly when enabling Istio. manage_base=false consumes a base release from an earlier stage. csr_address connects an externally managed istio-csr."
  validation {
    condition     = !var.enable_istio || contains(["sidecar", "ambient"], coalesce(var.istio.mode, "unset"))
    error_message = "Choose istio.mode = sidecar or ambient when enabling Istio."
  }
  validation {
    condition     = var.istio.mode != "ambient" || var.istio.cni_enabled
    error_message = "Ambient mode requires the Istio CNI component."
  }
  validation {
    condition     = !(var.enable_istio_csr && var.istio.csr_address != null)
    error_message = "Use the managed istio-csr or an external csr_address, not both."
  }
}

variable "cilium_istio_compatibility" {
  type        = bool
  default     = false
  nullable    = false
  description = "Enable Cilium socket-LB/CNI coexistence settings before a separately staged Istio install. Also enabled automatically when this invocation manages Istio."
}

variable "pki" {
  type = object({
    issuer_name                  = optional(string)
    issuer_kind                  = optional(string, "StepIssuer")
    issuer_group                 = optional(string, "certmanager.step.sm")
    root_ca_config_map           = optional(string)
    root_ca_key                  = optional(string, "ca.pem")
    cert_manager_service_account = optional(string, "cert-manager")
    cert_manager_namespace       = optional(string, "cert-manager")
  })
  default     = {}
  nullable    = false
  description = "Existing issuer and trusted-root ConfigMap for istio-csr. The ConfigMap must be in the istio-csr release namespace; a namespaced issuer must be in the istiod namespace. No private keys are read."
  validation {
    condition     = !var.enable_istio_csr || (var.pki.issuer_name != null && var.pki.root_ca_config_map != null)
    error_message = "istio-csr requires pki.issuer_name and pki.root_ca_config_map from the configuration stage."
  }
}

variable "write_only_values" {
  type        = map(list(object({ name = string, value = string, type = optional(string) })))
  default     = {}
  sensitive   = true
  ephemeral   = true
  description = "Ephemeral set_wo overrides keyed by component (including istio_cni). Increment that component's set_wo_revision when changing values."
}

variable "step_issuer_auto_approval" {
  type        = bool
  default     = false
  nullable    = false
  description = "Allow cert-manager auto-approval for Smallstep signers managed externally. Also enabled when managing step-issuer here. Override cert_manager.values to use a separate approval policy."
}
