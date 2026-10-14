<p align="center">
    <!-- terraform-kubernetes-foundation -->
    <img src="https://cdn.simpleicons.org/terraform/844FBA" alt="Terraform Logo" align="center" width="128">
    <h1 align="center">Ad Noctem Collective</h1>
    <h2 align="center"><code>foundation</code></h2>
</p>

[![License](https://img.shields.io/github/license/adnoctem/terraform-kubernetes-foundation?label=License)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-_>=_1.11-brightgreen?logo=terraform&logoColor=623CE4)][terraform]
[![OpenTofu](https://img.shields.io/badge/OpenTofu-_>=_1.11-brightgreen?logo=opentofu)][opentofu]
[![CI Status](https://github.com/adnoctem/terraform-kubernetes-foundation/actions/workflows/testing.yaml/badge.svg)](https://github.com/adnoctem/terraform-kubernetes-foundation/actions/workflows/testing.yaml)
[![GitHub Release](https://img.shields.io/github/v/release/adnoctem/terraform-kubernetes-foundation?label=Release)][github_releases]
[![GitHub Activity](https://img.shields.io/github/commit-activity/m/adnoctem/terraform-kubernetes-foundation?label=Commits)][github_commits]
[![Renovate](https://img.shields.io/badge/Renovate-enabled-brightgreen?logo=renovate&logoColor=1A1F6C)][renovate]
[![Pre-Commit](https://img.shields.io/badge/PreCommit-enabled-brightgreen?logo=precommit&logoColor=FAB040)][pre-commit]

A [Terraform module][module] for the controllers that establish a Kubernetes cluster before GitOps starts.
It works with caller-configured clusters and has no AWS, Azure, or Google provider dependencies.

## ✨ TL;DR

```hcl
module "foundation" {
  source  = "adnoctem/foundation/kubernetes"
  version = "~> 1.0"

  enable_cert_manager = true
  enable_argocd       = true
  argocd = {
    values = [yamlencode({ configs = { params = { "server.insecure" = false } } })]
  }
}
```

This source targets the upcoming first Registry release. Publish `adnoctem/release/helm` v2.0.0
first: foundation consumes that exact version. Local foundation examples also need that dependency.

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
chart, chart_version, timeouts, post-rendering, and all regular value overrides. Null options use provider
defaults. Foundation defaults to waiting for releases, a 600-second Helm timeout, and ten history entries.
Set versions explicitly when introducing another chart repository; do not rely on compatible defaults.

Values merge in this order: chart defaults, generated integration YAML, then caller `values` in list
order. Helm `set`, `set_list`, and `set_sensitive` overrides follow; keep their keys unique.
Use `yamlencode`, `file`, or `templatefile` to pass arbitrary chart settings.
Overrides can replace integration defaults, so changes to identities, services, or trust settings must
remain consistent across components. `releases` exposes the managed release identities.

Provider configuration belongs in the consuming root. The root only requires Helm; the optional
[configuration submodule](modules/configuration) requires Kubernetes. Both use provider versions `~> 3.3`.
Terraform and OpenTofu >= 1.11 are required for ephemeral/write-only inputs.

Ordinary values, sensitive values, and repository passwords can be retained in Terraform state.
Use `write_only_values = { component = [...] }` for ephemeral Helm `set_wo` inputs and increment the
component's `set_wo_revision` when changing them. This does not prevent Helm or charts storing Secrets
inside Kubernetes. Prefer existing Secret references for CA material and external credentials.

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
Argo CD owns downstream workloads such as Jenkins; do not configure it to reconcile these same Helm
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
## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_argocd"></a> [argocd](#module\_argocd) | adnoctem/release/helm | 2.0.0 |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | adnoctem/release/helm | 2.0.0 |
| <a name="module_cilium"></a> [cilium](#module\_cilium) | adnoctem/release/helm | 2.0.0 |
| <a name="module_istio_base"></a> [istio\_base](#module\_istio\_base) | adnoctem/release/helm | 2.0.0 |
| <a name="module_istio_cni_ambient"></a> [istio\_cni\_ambient](#module\_istio\_cni\_ambient) | adnoctem/release/helm | 2.0.0 |
| <a name="module_istio_cni_sidecar"></a> [istio\_cni\_sidecar](#module\_istio\_cni\_sidecar) | adnoctem/release/helm | 2.0.0 |
| <a name="module_istio_csr"></a> [istio\_csr](#module\_istio\_csr) | adnoctem/release/helm | 2.0.0 |
| <a name="module_istiod"></a> [istiod](#module\_istiod) | adnoctem/release/helm | 2.0.0 |
| <a name="module_step_certificates"></a> [step\_certificates](#module\_step\_certificates) | adnoctem/release/helm | 2.0.0 |
| <a name="module_step_issuer"></a> [step\_issuer](#module\_step\_issuer) | adnoctem/release/helm | 2.0.0 |
| <a name="module_ztunnel"></a> [ztunnel](#module\_ztunnel) | adnoctem/release/helm | 2.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_argocd"></a> [argocd](#input\_argocd) | argocd Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "argo-cd") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "argocd") namespace = optional(string, "argocd") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://argoproj.github.io/argo-helm") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = helm depName = argo-cd registryUrl = https://argoproj.github.io/argo-helm chart_version = optional(string, "10.10.3") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_cert_manager"></a> [cert\_manager](#input\_cert\_manager) | cert manager Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "cert-manager") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "cert-manager") namespace = optional(string, "cert-manager") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "oci://quay.io/jetstack/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = docker depName = quay.io/jetstack/charts/cert-manager chart_version = optional(string, "v1.21.2") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_cilium"></a> [cilium](#input\_cilium) | cilium Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "cilium") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "cilium") namespace = optional(string, "kube-system") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://helm.cilium.io") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = helm depName = cilium registryUrl = https://helm.cilium.io chart_version = optional(string, "1.20.2") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_cilium_istio_compatibility"></a> [cilium\_istio\_compatibility](#input\_cilium\_istio\_compatibility) | Enable Cilium socket-LB/CNI coexistence settings before a separately staged Istio install. Also enabled automatically when this invocation manages Istio. | `bool` | `false` | no |
| <a name="input_enable_argocd"></a> [enable\_argocd](#input\_enable\_argocd) | Manage argocd. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_cert_manager"></a> [enable\_cert\_manager](#input\_enable\_cert\_manager) | Manage cert manager. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_cilium"></a> [enable\_cilium](#input\_enable\_cilium) | Manage cilium. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_istio"></a> [enable\_istio](#input\_enable\_istio) | Manage istio. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_istio_base"></a> [enable\_istio\_base](#input\_enable\_istio\_base) | Manage istio base. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_istio_csr"></a> [enable\_istio\_csr](#input\_enable\_istio\_csr) | Manage istio csr. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_step_certificates"></a> [enable\_step\_certificates](#input\_enable\_step\_certificates) | Manage step certificates. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_enable_step_issuer"></a> [enable\_step\_issuer](#input\_enable\_step\_issuer) | Manage step issuer. False removes resources previously managed by this invocation. | `bool` | `false` | no |
| <a name="input_istio"></a> [istio](#input\_istio) | Coordinated Istio settings. Select sidecar or ambient explicitly when enabling Istio. manage\_base=false consumes a base release from an earlier stage. csr\_address connects an externally managed istio-csr. | ```object({ mode = optional(string) namespace = optional(string, "istio-system") # renovate: datasource = helm depName = istiod registryUrl = https://istio-release.storage.googleapis.com/charts chart_version = optional(string, "1.30.5") manage_base = optional(bool, true) cni_enabled = optional(bool, true) trust_domain = optional(string, "cluster.local") revision = optional(string, "default") ztunnel_service_account = optional(string, "ztunnel") csr_address = optional(string) })``` | `{}` | no |
| <a name="input_istio_base"></a> [istio\_base](#input\_istio\_base) | istio base Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "base") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "istio-base") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) chart_version = optional(string) wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_istio_cni"></a> [istio\_cni](#input\_istio\_cni) | istio cni Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "cni") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "istio-cni") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) chart_version = optional(string) wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_istio_csr"></a> [istio\_csr](#input\_istio\_csr) | istio csr Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "cert-manager-istio-csr") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "cert-manager-istio-csr") namespace = optional(string, "cert-manager") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "oci://quay.io/jetstack/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = docker depName = quay.io/jetstack/charts/cert-manager-istio-csr chart_version = optional(string, "v0.18.0") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_istiod"></a> [istiod](#input\_istiod) | istiod Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "istiod") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "istiod") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) chart_version = optional(string) wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_pki"></a> [pki](#input\_pki) | Existing issuer and trusted-root ConfigMap for istio-csr. The ConfigMap must be in the istio-csr release namespace; a namespaced issuer must be in the istiod namespace. No private keys are read. | ```object({ issuer_name = optional(string) issuer_kind = optional(string, "StepIssuer") issuer_group = optional(string, "certmanager.step.sm") root_ca_config_map = optional(string) root_ca_key = optional(string, "ca.pem") cert_manager_service_account = optional(string, "cert-manager") cert_manager_namespace = optional(string, "cert-manager") })``` | `{}` | no |
| <a name="input_step_certificates"></a> [step\_certificates](#input\_step\_certificates) | step certificates Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "step-certificates") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "step-certificates") namespace = optional(string, "step-ca") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://smallstep.github.io/helm-charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = helm depName = step-certificates registryUrl = https://smallstep.github.io/helm-charts chart_version = optional(string, "1.30.1") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_step_issuer"></a> [step\_issuer](#input\_step\_issuer) | step issuer Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "step-issuer") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "step-issuer") namespace = optional(string, "step-issuer") pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://smallstep.github.io/helm-charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) # renovate: datasource = helm depName = step-issuer registryUrl = https://smallstep.github.io/helm-charts chart_version = optional(string, "1.11.0") wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |
| <a name="input_step_issuer_auto_approval"></a> [step\_issuer\_auto\_approval](#input\_step\_issuer\_auto\_approval) | Allow cert-manager auto-approval for Smallstep signers managed externally. Also enabled when managing step-issuer here. Override cert\_manager.values to use a separate approval policy. | `bool` | `false` | no |
| <a name="input_write_only_values"></a> [write\_only\_values](#input\_write\_only\_values) | Ephemeral set\_wo overrides keyed by component (including istio\_cni). Increment that component's set\_wo\_revision when changing values. | `map(list(object({ name = string, value = string, type = optional(string) })))` | `{}` | no |
| <a name="input_ztunnel"></a> [ztunnel](#input\_ztunnel) | ztunnel Helm release overrides. Caller YAML follows integration defaults; optional null fields use provider defaults. | ```object({ atomic = optional(bool, false) chart = optional(string, "ztunnel") cleanup_on_fail = optional(bool) create_namespace = optional(bool, true) dependency_update = optional(bool) description = optional(string) devel = optional(bool) disable_crd_hooks = optional(bool) disable_openapi_validation = optional(bool) disable_webhooks = optional(bool) force_update = optional(bool) keyring = optional(string) lint = optional(bool) max_history = optional(number, 10) name = optional(string, "ztunnel") namespace = optional(string) pass_credentials = optional(bool) postrender = optional(object({ args = optional(list(string)) binary_path = string })) recreate_pods = optional(bool) render_subchart_notes = optional(bool) replace = optional(bool) repository = optional(string, "https://istio-release.storage.googleapis.com/charts") repository_ca_file = optional(string) repository_cert_file = optional(string) repository_key_file = optional(string) repository_password = optional(string) repository_username = optional(string) reset_values = optional(bool) reuse_values = optional(bool) set = optional(list(object({ name = string type = optional(string) value = optional(string) })), []) set_list = optional(list(object({ name = string value = list(string) })), []) set_sensitive = optional(list(object({ name = string type = optional(string) value = string })), []) set_wo_revision = optional(number) skip_crds = optional(bool) take_ownership = optional(bool) timeout = optional(number, 600) timeouts = optional(object({ create = optional(string) delete = optional(string) read = optional(string) update = optional(string) })) upgrade_install = optional(bool) values = optional(list(string), []) verify = optional(bool) chart_version = optional(string) wait = optional(bool, true) wait_for_jobs = optional(bool) })``` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_releases"></a> [releases](#output\_releases) | Managed release identities keyed by component. References carry release completion dependencies. |
<!-- END_TF_DOCS -->

### 🔃 Contributing

Refer to our [documentation for contributors][contributing] for development checks, native tests,
commit message formats, and versioning tips.

### 📥 Maintainers

This project is owned and maintained by [Ad Noctem Collective][org].
Refer to the [`AUTHORS`][authors] or [`CODEOWNERS`][owners] for more information.
You may also use the linked contact details to reach out directly.

### ©️ Copyright

- _Assets provided by:_ **[HashiCorp][hashicorp]**
- _Sources provided by:_ **[Ad Noctem Collective][org]** under the **[MIT License][license]**

<!-- File references -->

[license]: LICENSE
[contributing]: docs/CONTRIBUTING.md
[authors]: .github/AUTHORS
[owners]: .github/CODEOWNERS

<!-- General links -->

[org]: https://github.com/adnoctem
[terraform]: https://terraform.io
[opentofu]: https://opentofu.org/
[hashicorp]: https://www.hashicorp.com/
[github_releases]: https://github.com/adnoctem/terraform-kubernetes-foundation/releases
[github_commits]: https://github.com/adnoctem/terraform-kubernetes-foundation/commits/main/

<!-- Third-party -->

[module]: https://registry.terraform.io/modules/adnoctem/foundation/kubernetes/latest
[renovate]: https://renovatebot.com/
[pre-commit]: https://pre-commit.com/
