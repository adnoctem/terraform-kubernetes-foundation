# Staged cluster foundation

These are three independent Terraform roots/states, not modules applied together from a parent root.
They assume a reachable Kubernetes API, published release-wrapper dependency, and cluster credentials.
Keep each state's inputs when advancing; do not disable controllers installed in an earlier stage.

## 1. Controllers and the in-cluster CA

Prepare the cluster-specific Cilium YAML in `cilium_values`. In particular decide routing/IPAM,
kube-proxy replacement and API server access for this cluster. Applying a CNI can interrupt networking.
The example enables Cilium's Istio coexistence settings before the mesh is installed.

The default demonstrates in-cluster step-certificates **with existing CA material**. Provision the
`step-ca` namespace and the following objects through your existing secret/configuration process before
applying controllers; the chart does not create a new production root or import an offline root key:

| Object in `step-ca` | Required content |
| --- | --- |
| ConfigMap `step-certificates-config` | `ca.json` configured for the mounted paths, serving DNS name, and JWK provisioner. |
| ConfigMap `step-certificates-certs` | `root_ca.crt` and `intermediate_ca.crt`. |
| Secret `step-certificates-secrets` | The encrypted `intermediate_ca_key` referenced by `ca.json`. |
| Secret `step-certificates-ca-password` | `password` used to decrypt the signing key. |

The chart mounts config, certs, and secrets under `/home/step/{config,certs,secrets}`. Configure a suitable
storage class via `ca_values` and back up signing material and the CA database. Set serving DNS names
including `step-certificates.step-ca.svc.cluster.local` for the example URL.
The default disables `bootstrap.enabled`, `bootstrap.configmaps`, and `bootstrap.secrets`, and enables
`existingSecrets.enabled` and `existingSecrets.ca`. Upstream bootstrap can be deliberately enabled via
values for disposable experiments, but then turn off existingSecrets and explicitly configure its
configmaps/secrets; do not mix the two modes.

Apply `controllers/` with its own backend/state. It installs Cilium, cert-manager, step-issuer, the CA,
Istio base CRDs/namespace, and Argo CD. Wait for successful Helm completion and controller readiness.

To use an **external CA**, set `in_cluster_ca=false` from the first apply, skip the in-cluster CA objects,
and use the external URL in stage 2. Retain cert-manager and step-issuer. Changing from an existing
managed CA to an external one later needs a deliberate trust/backup migration before removing the CA.

## 2. Issuer, trust, and optional GitOps bootstrap

Create `step-provisioner` in `istio-system` with the JWK provisioner password under `password` using your
secret-management process. Plan and apply `configuration/` with the CA URL, public root PEM, provisioner
name, and public key ID. Its StepIssuer waits for Ready. The same independently verified public root
is mounted by istio-csr in stage 3; no private material goes through these Terraform inputs.

Set `bootstrap_application_spec` only if Terraform should own the initial Argo Application. For example,
encode a spec with project `default`, your Git repository URL/path and target revision, and destination
`https://kubernetes.default.svc`. The referenced repository must exclude Terraform-owned foundation
resources. Private Git repository credentials must already be configured in Argo CD.

Do not combine this root with the controller installation: custom-resource schemas must exist before
planning, even when Terraform module dependencies are present.

## 3. Istio runtime

Plan and apply `runtime/` with `istio_mode="sidecar"` or `istio_mode="ambient"`. This state owns istio-csr,
istiod, CNI, and (ambient only) ztunnel. It references the existing base release, issuer, and root bundle.
Enroll workloads/namespaces using the selected Istio mode after verifying certificate issuance and
traffic. Do not let Argo manage these Terraform-owned controllers.

No single cluster version or environment is claimed to be validated by these examples. Before a real
rollout, check chart support for your Kubernetes version, network architecture, storage, and PKI policy.
Destroy in reverse order, reviewing retained CRDs, persistent volumes, and CA backups explicitly.
