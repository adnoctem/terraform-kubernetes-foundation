# Architecture and trust

The root is a curated catalog of explicitly named release modules. Independent releases may install
in parallel. Cilium precedes the managed controllers; cert-manager precedes step-issuer and istio-csr;
istio-csr precedes istiod. Argo CD only depends on Cilium: if its exposure needs an ingress controller
or mesh installed elsewhere, express that dependency in the calling configuration.

## Istio

Choose sidecar or ambient explicitly. Both use base CRDs and istiod. Sidecar CNI is optional; ambient
requires CNI and ztunnel. The two CNI resource addresses allow the different installation orders without
a Terraform dependency cycle. Changing mode on an existing cluster is a migration, not a normal toggle:
plan workload enrollment changes and move the CNI module state between `istio_cni_sidecar[0]` and
`istio_cni_ambient[0]` under the caller's foundation address before applying. Rehearse this first.

Cilium coexistence sets `socketLB.hostNamespaceOnly=true` and `cni.exclusive=false`. It does not select
IPAM, API server reachability, kube-proxy replacement, or routing for the caller. Follow the
[Cilium Istio guidance](https://docs.cilium.io/en/stable/network/servicemesh/istio/) for L7 ownership;
do not independently enable competing L7 interception without a deliberate design.

Istio without a CSR endpoint uses its own default CA. With managed or external istio-csr, istiod uses
`global.caAddress`, `global.pilotCertProvider=custom`, and disables its internal CA. Ztunnel uses the same
CSR endpoint. Ambient mode configures the CSR server's trusted node account to match ztunnel's namespace
and service account. Caller YAML must preserve that agreement if it overrides these identities.

## PKI

Smallstep's issuer controller, cert-manager, and istio-csr are separate components. Issuers and public
root bundles must exist before installing istio-csr. Namespaced issuers live in the istiod namespace;
cluster issuers use an explicitly namespaced provisioner-password reference. The root bundle ConfigMap
lives in the istio-csr namespace. Mounting this explicit root avoids deriving trust from a returned leaf
certificate. The issuer endpoint must be reachable from the issuer controller.

When step-issuer is enabled, cert-manager's approver is configured for the StepIssuer and
StepClusterIssuer signer names in addition to its built-in issuers. If controllers are split across
invocations, set `step_issuer_auto_approval=true` on the cert-manager invocation. This permits automatic
approval for those signers; installations using a dedicated approver policy should override the chart
values accordingly. The cert-manager controller account name and namespace are derived from the component settings for
step-issuer approval RBAC. `pki.cert_manager_service_account` and `pki.cert_manager_namespace` override
that derivation when the controller is external or its identity is supplied through raw chart values.
Without an explicit account name, derivation follows the pinned cert-manager chart's fullname helper
(or `default` when account creation is disabled). Custom charts, `nameOverride`, and `fullnameOverride`
need an explicit PKI account override if they change that convention.

Existing Secrets keep private CA/provisioner material outside module inputs. CA initialization,
backup, rotation, recovery, and availability remain operator responsibilities. The example mounts
existing intermediate signing material; it does not upload an offline root private key.

## Ownership and cloud integration

The configuration submodule only creates requested namespaces, public trust bundles, Smallstep issuer
objects, and Argo bootstrap Applications. Its `spec_yaml` input preserves the full Argo Application spec.
Field-manager conflict forcing and Argo deletion finalizers are opt-in. Keep one owner for each object.
Do not duplicate a namespace between this module and another Terraform resource.

Future EKS/GKE/AKS adapters should expose controller identity and cloud settings to the same generic
Helm interfaces. AWS/GCP/Azure providers and IAM resources belong in separate modules, so vanilla cluster
users never need cloud credentials or IAM-disable switches.

## References

- [Istio sidecar Helm installation](https://istio.io/latest/docs/setup/install/helm/)
- [Istio ambient Helm installation](https://istio.io/latest/docs/ambient/install/helm/)
- [istio-csr installation](https://cert-manager.io/docs/usage/istio-csr/installation/)
- [Smallstep Helm charts](https://github.com/smallstep/helm-charts)
- [Kubernetes custom resources and Terraform planning](https://developer.hashicorp.com/terraform/tutorials/kubernetes/kubernetes-provider)

## Service-account mappings

Role names below are module input keys, not necessarily the chart's own field names. A populated field
without a mapping fails validation. Unlisted roles need explicit `service_account_paths` mappings.

| Component | Role | Supported fields |
| --- | --- | --- |
| `cilium` | `agent` | `name`, `create`, `annotations`, `pod_labels` |
| `cilium` | `operator` | `name`, `create`, `annotations`, `pod_labels` |
| `cilium` | `relay` | `name`, `create`, `annotations`, `pod_labels` |
| `cilium` | `ui` | `name`, `create`, `annotations`, `pod_labels` |
| `cert_manager` | `controller` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `cert_manager` | `webhook` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `cert_manager` | `cainjector` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `cert_manager` | `startupapicheck` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `step_certificates` | `default` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `step_issuer` | `default` | `name`, `create`, `annotations` |
| `istio_base` | None | The chart has no mapped workload identity interface. |
| `istiod` | `default` | `annotations`, `pod_labels` |
| `istio_cni` | `default` | `pod_labels` |
| `ztunnel` | `default` | `name`, `annotations`, `labels`, `pod_labels` |
| `istio_csr` | `default` | `pod_labels` |
| `argocd` | `controller` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `argocd` | `server` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `argocd` | `repo_server` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `argocd` | `application_set` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `argocd` | `notifications` | `name`, `create`, `annotations`, `labels`, `pod_labels` |
| `argocd` | `dex` | `name`, `create`, `annotations`, `pod_labels` |
| `argocd` | `redis` | `name`, `create`, `annotations`, `pod_labels` |
| `argocd` | `redis_secret_init` | `name`, `create`, `annotations`, `pod_labels` |
| `argocd` | `commit_server` | `name`, `create`, `annotations`, `labels`, `pod_labels` |

A mapping is a list of literal keys, such as `["controller", "serviceAccount", "annotations"]`.
Overrides merge by component, role, and field; other mappings remain intact. Changing the chart/version
can invalidate these paths, so CI renders fixtures containing unique markers and checks every marker
survives in the chart output. Providing a role does not enable an otherwise disabled chart component
(e.g. Cilium Hubble UI or Argo commit-server); enable it through chart values as well.

The pinned step-issuer chart only binds its named account when `serviceAccount.create=true`. Its
convenience input rejects a custom name with `create=false`. Other charts that support existing accounts
can use that combination, but Helm will not apply annotations to accounts it does not create.

Istio exposes fewer account controls than other charts. Istiod maps account annotations; CNI and
istio-csr expose only workload labels through this helper. Ztunnel's name maps to `resourceName`, which
also renames its other chart resources; its labels/annotations apply across the chart. These are chart
limitations, not silently invented field paths.

The generic interfaces carry account names, annotations, and workload labels. They can consume output
from future AWS/GCP/Azure adapters, but do not provision cloud trust or assume every identity mechanism
uses account annotations. Cloud-specific associations and IAM dependencies belong to those adapters.
