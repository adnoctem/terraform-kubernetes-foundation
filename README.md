# Kubernetes Foundation Terraform module

Manage the controllers that establish a Kubernetes cluster before GitOps starts.
The module supports caller-configured clusters without AWS, Azure, or Google provider dependencies.

## Usage

Copy this configuration into `main.tf` for an existing cluster.

```hcl
module "foundation" {
  source  = "registry.terraform.io/adnoctem/foundation/kubernetes"
  version = "~> 1.0"

  enable_cert_manager = true
  enable_argocd       = true
  argocd = {
    values_object = { configs = { params = { "server.insecure" = false } } }
  }
}
```

Foundation pins `registry.terraform.io/adnoctem/release/helm` to v2.0.0. The explicit hostname
ensures Terraform and OpenTofu install the same dependency from the Terraform Registry. Local
foundation examples also download that dependency.

## Examples

- [Basic](examples/basic): a controller release with shared defaults and structured values.
- [Full](examples/full): every root input and release setting for an already prepared cluster, plus
  a separate complete configuration-submodule example.
- [Staged](examples/staged): separate controller, issuer/trust, and mesh runtime states for bootstrap.

## Components and configuration

Every component is disabled by default. Enable the components this Terraform state will own:

| Enable input | Release settings | Purpose |
| --- | --- | --- |
| `enable_cilium` | `cilium` | Cluster networking. |
| `enable_cert_manager` | `cert_manager` | Certificate controllers and CRDs. |
| `enable_step_certificates` | `step_certificates` | In-cluster Smallstep CA using pre-provisioned material. |
| `enable_step_issuer` | `step_issuer` | Smallstep cert-manager issuer controller. |
| `enable_istio_base` | `istio_base` | Istio CRDs, optionally owned by a separate controller stage. |
| `enable_istio` | `istiod`, `istio_cni`, `ztunnel`, `istio_base`, `istio` | Explicit sidecar or ambient mode. |
| `enable_istio_csr` | `istio_csr`, `pki` | Connect Istio to a pre-existing cert-manager issuer and trusted root. |
| `enable_argocd` | `argocd` | GitOps controller; application bootstrapping is optional and separate. |

The settings objects expose the release wrapper's Helm options, including name, namespace, repository,
chart, chart_version, timeouts, post-rendering, and all regular value overrides. Foundation defaults to
waiting for releases, a 600-second Helm timeout, and ten history entries. `release_defaults` sets shared
`atomic`, `create_namespace`, `wait`, `timeout`, `max_history`, `cleanup_on_fail`, `wait_for_jobs`, and
`lint` settings. Non-null component settings override shared defaults; explicit false and zero are
preserved. Null component settings inherit. Other null options use provider defaults.
Set versions explicitly when introducing another chart repository; do not rely on compatible defaults.

Values merge in this order: chart defaults, generated integration YAML, mapped `service_accounts`,
`values_object`, then caller `values` in list order. Helm `set`, `set_list`, `set_sensitive`, and write-only
overrides follow; their exact paths must be unique. Helm performs the nested merge. Use `values_object`
for a native HCL object or `file`/`templatefile` for arbitrary YAML. Structured values and ordinary YAML
have the same state persistence behavior; neither is a write-only secret channel.
Overrides can replace integration defaults, so changes to identities, services, or trust settings must
remain consistent across components. `releases` exposes the managed release identities.

Provider configuration belongs in the consuming root. The root only requires Helm; the optional
[configuration submodule](modules/configuration) requires Kubernetes. Both use provider versions `~> 3.3`.
Terraform and OpenTofu >= 1.11 are required for ephemeral/write-only inputs.

Ordinary values, sensitive values, and repository passwords can be retained in Terraform state.
Use `write_only_values = { component = [...] }` for ephemeral Helm `set_wo` inputs and increment the
component's `set_wo_revision` when changing them. This does not prevent Helm or charts storing Secrets
inside Kubernetes. Prefer existing Secret references for CA material and external credentials.

## Shared settings and identities

```hcl
release_defaults = {
  timeout     = 900
  max_history = 5
}
cert_manager = {
  values_object = { replicaCount = 2 }
  service_accounts = {
    controller = {
      name        = "certificates"
      annotations = { "example.com/identity" = "existing-identity" }
    }
  }
}
argocd = {
  timeout = 1200
  wait    = false
}
```

Each component accepts `service_accounts` by logical role. Foundation supplies verified chart paths;
see the [supported-role table](docs/ARCHITECTURE.md#service-account-mappings). Use
`service_account_paths` within a component to override individual role/field mappings for another chart.
Raw values remain available, but changes to service names and account identities must preserve the
relationships between controllers.

Cert-manager's controller account name and namespace automatically feed step-issuer's approval RBAC.
The explicit `pki.cert_manager_service_account`/`cert_manager_namespace` inputs override that derivation
for external controllers. A configured ztunnel account name also updates istio-csr's ambient trust.
Raw YAML/`set` overrides are not inspected to infer identities; keep dependent settings consistent when
using those escape hatches. Leave settings empty or use a conditional object to toggle identity wiring.
Cloud IAM and federation resources remain the responsibility of separately invoked adapters.

## Installation stages

Use [basic](examples/basic) for a small controller installation, or the
[staged example](examples/staged) for Cilium, Smallstep PKI, Istio, and Argo CD.

1. Install controllers and CRDs. Select Cilium settings for the actual cluster; set
   `cilium_istio_compatibility = true` if Istio will be managed by a later invocation.
2. In a separate root/state, plan and apply issuer and public trust configuration after the CRDs exist.
3. Install istio-csr and the selected Istio mode after the issuer is Ready and trust material is present.

Kubernetes discovers custom-resource schemas during planning. Module `depends_on` does not allow
`kubernetes_manifest` to plan a new CRD and its first instances together. Keep these stages separate;
do not toggle earlier components off to advance to the next stage. Disabling an owned component removes it.
There is no routine `-target` workflow or runner script.

The module orders sidecar CNI before istiod, and ambient CNI after istiod and before ztunnel.
`istio.mode` is required when enabling Istio. `istio.manage_base = false` consumes the base release
from the controller stage. See [architecture and trust](docs/ARCHITECTURE.md) before changing mesh mode.

Smallstep can run in the cluster or externally. External CA users leave `enable_step_certificates`
false and configure their URL, public trust bundle, and provisioner Secret reference in the
configuration module. The CA private/root key is never generated by this module.
The in-cluster default disables chart bootstrap and consumes existing Secrets and ConfigMaps.

Terraform retains ownership of the foundation and any explicitly configured bootstrap Application.
Argo CD owns downstream workloads; do not configure it to reconcile these same Helm
releases or bootstrap objects. Future cloud integrations can add controllers here while keeping
IAM, workload identity, and cloud resources in separate provider-specific modules.

## Development

Run `terraform init -backend=false`, `terraform validate`, `terraform test`, and `pre-commit run --all-files`.
Native tests use mocked providers and cover both mesh modes, ordering inputs, trust, scopes, and invalid
settings. CI also renders the charts from the actual Terraform fixture values in both modes. Rendering
does not verify Kubernetes admission, controller readiness, certificate issuance, or traffic.
Live acceptance remains a separate step; see [follow-up work](docs/TODO.md).

The CI matrix covers Terraform 1.11.4/1.16.6 and OpenTofu 1.11.14/1.13.1.
See [upgrading](docs/UPGRADING.md) and the generated [schema inventory](docs/SCHEMA.md).
Generate reports with `formr schema . -o docs/SCHEMA.md` and check with
`formr check . --report docs/SCHEMA.md`. The configuration submodule has its own report. Current Formr only traverses local module sources,
so the root report truthfully marks the Registry dependencies incomplete and `formr check` fails that
inventory policy. Publication alone does not resolve this analyzer limitation. Use the release
wrapper's resource report together with the native tests until Formr supports installed Registry modules.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| terraform | >= 1.11 |
| helm | ~> 3.3 |

## Providers

No providers.

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| argocd | argocd Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "argo-cd") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "argocd") namespace = optional(string, "argocd") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://argoproj.github.io/argo-helm") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = helm depName = argo-cd registryUrl = https://argoproj.github.io/argo-helm chart_version = optional(string, "10.10.3") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| cert\_manager | cert manager Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "cert-manager") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "cert-manager") namespace = optional(string, "cert-manager") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "oci://quay.io/jetstack/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = docker depName = quay.io/jetstack/charts/cert-manager chart_version = optional(string, "v1.21.2") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| cilium | cilium Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "cilium") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "cilium") namespace = optional(string, "kube-system") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://helm.cilium.io") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = helm depName = cilium registryUrl = https://helm.cilium.io chart_version = optional(string, "1.20.2") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| cilium\_istio\_compatibility | Enable Cilium socket-LB/CNI coexistence settings before a separately staged Istio install. Also enabled automatically when this invocation manages Istio. | `bool` | `false` | no |
| enable\_argocd | Manage argocd. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_cert\_manager | Manage cert manager. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_cilium | Manage cilium. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_istio | Manage istio. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_istio\_base | Manage istio base. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_istio\_csr | Manage istio csr. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_step\_certificates | Manage step certificates. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| enable\_step\_issuer | Manage step issuer. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| istio | Coordinated Istio settings. Select sidecar or ambient explicitly when enabling Istio. manage\_base=false consumes a base release from an earlier stage. csr\_address connects an externally managed istio-csr. | ```object({ mode = optional(string) namespace = optional(string, "istio-system") # renovate: datasource = helm depName = istiod registryUrl = https://istio-release.storage.googleapis.com/charts chart_version = optional(string, "1.30.5") manage_base = optional(bool, true) cni_enabled = optional(bool, true) trust_domain = optional(string, "cluster.local") revision = optional(string, "default") ztunnel_service_account = optional(string, "ztunnel") csr_address = optional(string) })``` | `{}` | no |
| istio\_base | istio base Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "base") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "istio-base") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) chart_version = optional(string) wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| istio\_cni | istio cni Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "cni") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "istio-cni") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) chart_version = optional(string) wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| istio\_csr | istio csr Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "cert-manager-istio-csr") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "cert-manager-istio-csr") namespace = optional(string, "cert-manager") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "oci://quay.io/jetstack/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = docker depName = quay.io/jetstack/charts/cert-manager-istio-csr chart_version = optional(string, "v0.18.0") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| istiod | istiod Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "istiod") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "istiod") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) chart_version = optional(string) wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| pki | Existing issuer and trusted-root ConfigMap for istio-csr. The ConfigMap must be in the istio-csr release namespace; a namespaced issuer must be in the istiod namespace. No private keys are read. | ```object({ issuer_name = optional(string) issuer_kind = optional(string, "StepIssuer") issuer_group = optional(string, "certmanager.step.sm") root_ca_config_map = optional(string) root_ca_key = optional(string, "ca.pem") cert_manager_service_account = optional(string) cert_manager_namespace = optional(string) })``` | `{}` | no |
| release\_defaults | Shared operational release settings. Non-null per-component settings override these; null inherits. False and zero remain explicit overrides. | ```object({ atomic = optional(bool, false) create_namespace = optional(bool, true) wait = optional(bool, true) timeout = optional(number, 600) max_history = optional(number, 10) cleanup_on_fail = optional(bool) wait_for_jobs = optional(bool) lint = optional(bool) })``` | `{}` | no |
| step\_certificates | step certificates Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "step-certificates") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "step-certificates") namespace = optional(string, "step-ca") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://smallstep.github.io/helm-charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = helm depName = step-certificates registryUrl = https://smallstep.github.io/helm-charts chart_version = optional(string, "1.30.1") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| step\_issuer | step issuer Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "step-issuer") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "step-issuer") namespace = optional(string, "step-issuer") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://smallstep.github.io/helm-charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) # renovate: datasource = helm depName = step-issuer registryUrl = https://smallstep.github.io/helm-charts chart_version = optional(string, "1.11.0") wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |
| step\_issuer\_auto\_approval | Allow cert-manager auto-approval for Smallstep signers managed externally. Also enabled when managing step-issuer here. Override cert\_manager.values to use a separate approval policy. | `bool` | `false` | no |
| write\_only\_values | Ephemeral set\_wo overrides keyed by component (including istio\_cni). Increment that component's set\_wo\_revision when changing values. | `map(list(object({ name = string, value = string, type = optional(string) })))` | `{}` | no |
| ztunnel | ztunnel Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool) chart = optional(string, "ztunnel") cleanup_on_fail = optional(bool) create_namespace = optional(bool) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number) name = optional(string, "ztunnel") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) values_object = optional(any) service_accounts = optional(map(object({ name = optional(string) create = optional(bool) annotations = optional(map(string), {}) labels = optional(map(string), {}) pod_labels = optional(map(string), {}) })), {}) service_account_paths = optional(map(map(list(string))), {}) verify = optional(bool) chart_version = optional(string) wait = optional(bool) wait_for_jobs = optional(bool) })``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| releases | Managed release identities keyed by component. References carry release completion dependencies. |
<!-- END_TF_DOCS -->

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for local checks and contribution guidelines, and
[UPGRADING.md](docs/UPGRADING.md) for compatibility and acceptance checks.

## Authors

Maintained by [Ad Noctem Collective](https://github.com/adnoctem).
See [AUTHORS](.github/AUTHORS) and [CODEOWNERS](.github/CODEOWNERS).

## License

MIT. See [LICENSE](LICENSE).
