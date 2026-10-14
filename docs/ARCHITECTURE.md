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
values accordingly. `pki.cert_manager_service_account` and `pki.cert_manager_namespace` configure the
step-issuer approval RBAC and must match the actual cert-manager service account.

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
