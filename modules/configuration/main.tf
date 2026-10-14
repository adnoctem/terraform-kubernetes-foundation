resource "kubernetes_namespace_v1" "current" {
  for_each = var.namespaces
  metadata {
    name        = coalesce(each.value.name, each.key)
    labels      = each.value.labels
    annotations = each.value.annotations
  }
  wait_for_default_service_account = each.value.wait_for_default_service_account
  timeouts { delete = each.value.delete_timeout }
}

resource "kubernetes_config_map_v1" "trusted_root" {
  for_each = var.trusted_roots
  metadata {
    name        = coalesce(each.value.name, each.key)
    namespace   = each.value.namespace
    labels      = each.value.labels
    annotations = each.value.annotations
  }
  data        = merge(each.value.data, { (each.value.key) = each.value.pem })
  binary_data = each.value.binary_data
  immutable   = each.value.immutable
  depends_on  = [kubernetes_namespace_v1.current]
}

resource "kubernetes_manifest" "step_issuer" {
  for_each = var.step_issuers
  manifest = {
    apiVersion = "certmanager.step.sm/v1beta1"
    kind       = each.value.kind
    metadata = merge({
      name        = coalesce(each.value.name, each.key)
      labels      = each.value.labels
      annotations = each.value.annotations
    }, each.value.kind == "StepIssuer" ? { namespace = each.value.namespace } : {})
    spec = {
      url      = each.value.url
      caBundle = base64encode(each.value.ca_bundle_pem)
      provisioner = {
        name = each.value.provisioner.name
        kid  = each.value.provisioner.kid
        passwordRef = merge({
          name = each.value.provisioner.password_ref.name
          key  = each.value.provisioner.password_ref.key
        }, each.value.kind == "StepClusterIssuer" ? { namespace = each.value.provisioner.password_ref.namespace } : {})
      }
    }
  }
  dynamic "wait" {
    for_each = each.value.wait_ready ? [true] : []
    content {
      condition {
        type   = "Ready"
        status = "True"
      }
    }
  }
  computed_fields = var.computed_fields
  field_manager {
    name            = var.field_manager.name
    force_conflicts = var.field_manager.force_conflicts
  }
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
  depends_on = [kubernetes_namespace_v1.current]
}

resource "kubernetes_manifest" "argo_application" {
  for_each = var.argo_applications
  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name        = coalesce(each.value.name, each.key)
      namespace   = each.value.namespace
      labels      = each.value.labels
      annotations = each.value.annotations
      finalizers  = each.value.finalizers
    }
    spec = yamldecode(each.value.spec_yaml)
  }
  dynamic "wait" {
    for_each = length(each.value.wait_fields) > 0 ? [each.value.wait_fields] : []
    content { fields = wait.value }
  }
  computed_fields = var.computed_fields
  field_manager {
    name            = var.field_manager.name
    force_conflicts = var.field_manager.force_conflicts
  }
  timeouts {
    create = var.timeouts.create
    update = var.timeouts.update
    delete = var.timeouts.delete
  }
  depends_on = [kubernetes_namespace_v1.current]
}
