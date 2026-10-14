# Foundation configuration

Create only the requested namespaces, public root ConfigMaps, StepIssuer/StepClusterIssuer resources,
and optional Argo bootstrap Applications. Configure the Kubernetes provider in the caller.

Apply the root module's controllers and CRDs **before planning** this module. The Kubernetes provider
needs those schemas during planning. See the [staged example](../../examples/staged) for separate
controller, configuration, and runtime states.

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
## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | ~> 3.3 |

## Modules

No modules.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_argo_applications"></a> [argo\_applications](#input\_argo\_applications) | Explicitly Terraform-owned Argo bootstrap Applications. Argo CRDs must already exist. spec\_yaml permits the full Application spec, including multi-source configurations. Avoid having Argo manage these same objects. | ```map(object({ name = optional(string) namespace = optional(string, "argocd") spec_yaml = string labels = optional(map(string), {}) annotations = optional(map(string), {}) finalizers = optional(list(string), []) wait_fields = optional(map(string), {}) }))``` | `{}` | no |
| <a name="input_computed_fields"></a> [computed\_fields](#input\_computed\_fields) | Manifest fields Kubernetes may modify. Extend for admission-controller mutations when necessary. | `list(string)` | ```[ "metadata.annotations", "metadata.labels" ]``` | no |
| <a name="input_field_manager"></a> [field\_manager](#input\_field\_manager) | Server-side apply ownership for custom resources. Force-conflicts is opt-in. | `object({ name = optional(string, "terraform-foundation"), force_conflicts = optional(bool, false) })` | `{}` | no |
| <a name="input_namespaces"></a> [namespaces](#input\_namespaces) | Optional namespaces owned by this module. Omit namespaces owned by Helm or another configuration. Names default to map keys. | ```map(object({ name = optional(string) labels = optional(map(string), {}) annotations = optional(map(string), {}) wait_for_default_service_account = optional(bool, false) delete_timeout = optional(string) }))``` | `{}` | no |
| <a name="input_step_issuers"></a> [step\_issuers](#input\_step\_issuers) | StepIssuer/StepClusterIssuer resources. Their CRDs must exist before planning. Referenced provisioner Secrets must already exist. Public CA PEM is encoded once as required by the API. | ```map(object({ name = optional(string) kind = optional(string, "StepIssuer") namespace = optional(string) url = string ca_bundle_pem = string provisioner = object({ name = string kid = string password_ref = object({ name = string, key = string, namespace = optional(string) }) }) labels = optional(map(string), {}) annotations = optional(map(string), {}) wait_ready = optional(bool, true) }))``` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Custom resource operation and readiness timeouts. | `object({ create = optional(string, "10m"), update = optional(string, "10m"), delete = optional(string, "10m") })` | `{}` | no |
| <a name="input_trusted_roots"></a> [trusted\_roots](#input\_trusted\_roots) | Public CA bundles in ConfigMaps. PEM is stored under key, overriding that key in data. Never pass a private key. | ```map(object({ name = optional(string) namespace = string pem = string key = optional(string, "ca.pem") labels = optional(map(string), {}) annotations = optional(map(string), {}) immutable = optional(bool, false) data = optional(map(string), {}) binary_data = optional(map(string), {}) }))``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_argo_applications"></a> [argo\_applications](#output\_argo\_applications) | Terraform-owned bootstrap Application references. |
| <a name="output_namespaces"></a> [namespaces](#output\_namespaces) | Managed namespace names. |
| <a name="output_step_issuers"></a> [step\_issuers](#output\_step\_issuers) | Issuer references. Output depends on configured readiness checks. |
| <a name="output_trusted_roots"></a> [trusted\_roots](#output\_trusted\_roots) | Trusted-root ConfigMap references for the next stage. |
<!-- END_TF_DOCS -->
