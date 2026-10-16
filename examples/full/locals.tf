locals {
  # Every release uses this complete profile, with chart-specific values below.
  release_options = {
    atomic                     = false
    cleanup_on_fail            = true
    create_namespace           = true
    dependency_update          = false
    description                = "Managed platform release"
    devel                      = false
    disable_crd_hooks          = false
    disable_openapi_validation = false
    disable_webhooks           = false
    force_update               = false
    keyring                    = var.keyring
    lint                       = false
    max_history                = 10
    pass_credentials           = false
    postrender = {
      binary_path = "cat"
      args        = ["-"]
    }
    recreate_pods         = false
    render_subchart_notes = true
    replace               = false
    repository_ca_file    = var.repository_auth.ca_file
    repository_cert_file  = var.repository_auth.cert_file
    repository_key_file   = var.repository_auth.key_file
    repository_password   = var.repository_auth.password
    repository_username   = var.repository_auth.username
    reset_values          = true
    reuse_values          = false
    set                   = []
    set_list              = []
    set_sensitive         = []
    set_wo_revision       = null
    skip_crds             = false
    take_ownership        = false
    timeout               = 600
    timeouts = {
      create = "15m"
      update = "15m"
      read   = "5m"
      delete = "10m"
    }
    upgrade_install       = false
    values                = []
    values_object         = {}
    service_accounts      = {}
    service_account_paths = {}
    verify                = false
    wait                  = true
    wait_for_jobs         = true
  }
}
