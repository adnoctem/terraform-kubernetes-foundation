# Kubernetes Foundation Configuration Terraform module

Create only the requested namespaces, public root ConfigMaps, StepIssuer/StepClusterIssuer resources,
and optional Argo bootstrap Applications. Configure the Kubernetes provider in the caller.

Apply the root module's controllers and CRDs **before planning** this module. The Kubernetes provider
needs those schemas during planning. See the [staged example](../../examples/staged) for separate
controller, configuration, and runtime states.

## Usage

The controllers and custom-resource definitions must already exist before planning. This example
configures a namespaced issuer from an existing CA and provisioner Secret. Put it in `main.tf`.

```hcl
variable "ca" {
  description = "Existing CA endpoint, public trust bundle, and provisioner details."
  type = object({
    url              = string
    root_pem         = string
    provisioner_name = string
    provisioner_kid  = string
  })
}

module "configuration" {
  source  = "registry.terraform.io/adnoctem/foundation/kubernetes//modules/configuration"
  version = "~> 1.0"

  step_issuers = {
    cluster = {
      namespace     = "platform-system"
      url           = var.ca.url
      ca_bundle_pem = var.ca.root_pem
      provisioner = {
        name         = var.ca.provisioner_name
        kid          = var.ca.provisioner_kid
        password_ref = { name = "ca-provisioner", key = "password" }
      }
    }
  }
}
```

The `platform-system` namespace and `ca-provisioner` Secret must already exist. Pass public PEM only;
the provisioner password remains in its existing Secret.

## Examples

- [Staged configuration](../../examples/staged/configuration): issuer and trust configuration after controllers exist.
- [Full configuration](../../examples/full/configuration): every input and nested field, including both issuer scopes.

## Configuration

The issuer URL may point to an in-cluster or external Smallstep CA. Pass the public PEM bundle as
`ca_bundle_pem`; the module base64-encodes it once. Supply a reference to an already existing provisioner
password Secret. A StepIssuer and its Secret share a namespace. A StepClusterIssuer has no namespace
and requires `password_ref.namespace`.

Trust ConfigMaps contain public certificates only. For istio-csr, put the issuer in the istiod namespace
and the root bundle in the CSR release namespace. Namespaces are optional: only include ones this state
owns. Avoid owning the same namespace through another Terraform resource.

Argo `spec_yaml` is the full Application spec encoded as YAML. Only explicitly requested Applications
are managed; deletion finalizers and waiting for application fields are opt-in. Do not let Argo reconcile
these same bootstrap objects or the Terraform-owned foundation releases.

The [schema report](SCHEMA.md) records the selected Kubernetes resource interfaces. Generate with
`formr schema modules/configuration -o modules/configuration/SCHEMA.md` from the repository root.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11 |
| kubernetes | ~> 3.3 |

## Providers

| Name | Version |
| ---- | ------- |
| kubernetes | ~> 3.3 |

## Resources

| Name | Type |
| ---- | ---- |
| [kubernetes_config_map_v1.trusted_root](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1) | resource |
| [kubernetes_manifest.argo_application](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_manifest.step_issuer](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/manifest) | resource |
| [kubernetes_namespace_v1.current](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/namespace_v1) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| argo\_applications | Explicitly Terraform-owned Argo bootstrap Applications. Argo CRDs must already exist. spec\_yaml permits the full Application spec, including multi-source configurations. Avoid having Argo manage these same objects. | ```map(object({ name = optional(string) namespace = optional(string, "argocd") spec_yaml = string labels = optional(map(string), {}) annotations = optional(map(string), {}) finalizers = optional(list(string), []) wait_fields = optional(map(string), {}) }))``` | `{}` | no |
| computed\_fields | Manifest fields Kubernetes may modify. Extend for admission-controller mutations when necessary. | `list(string)` | ```[ "metadata.annotations", "metadata.labels" ]``` | no |
| field\_manager | Server-side apply ownership for custom resources. Force-conflicts is opt-in. | `object({ name = optional(string, "terraform-foundation"), force_conflicts = optional(bool, false) })` | `{}` | no |
| namespaces | Optional namespaces owned by this module. Omit namespaces owned by Helm or another configuration. Names default to map keys. | ```map(object({ name = optional(string) labels = optional(map(string), {}) annotations = optional(map(string), {}) wait_for_default_service_account = optional(bool, false) delete_timeout = optional(string) }))``` | `{}` | no |
| step\_issuers | StepIssuer/StepClusterIssuer resources. Their CRDs must exist before planning. Referenced provisioner Secrets must already exist. Public CA PEM is encoded once as required by the API. | ```map(object({ name = optional(string) kind = optional(string, "StepIssuer") namespace = optional(string) url = string ca_bundle_pem = string provisioner = object({ name = string kid = string password_ref = object({ name = string, key = string, namespace = optional(string) }) }) labels = optional(map(string), {}) annotations = optional(map(string), {}) wait_ready = optional(bool, true) }))``` | `{}` | no |
| timeouts | Custom resource operation and readiness timeouts. | `object({ create = optional(string, "10m"), update = optional(string, "10m"), delete = optional(string, "10m") })` | `{}` | no |
| trusted\_roots | Public CA bundles in ConfigMaps. PEM is stored under key, overriding that key in data. Never pass a private key. | ```map(object({ name = optional(string) namespace = string pem = string key = optional(string, "ca.pem") labels = optional(map(string), {}) annotations = optional(map(string), {}) immutable = optional(bool, false) data = optional(map(string), {}) binary_data = optional(map(string), {}) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| argo\_applications | Terraform-owned bootstrap Application references. |
| namespaces | Managed namespace names. |
| step\_issuers | Issuer references. Output depends on configured readiness checks. |
| trusted\_roots | Trusted-root ConfigMap references for the next stage. |
<!-- END_TF_DOCS -->
