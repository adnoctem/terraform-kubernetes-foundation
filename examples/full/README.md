# Full Kubernetes foundation example

This example shows every root input and every component's release setting for an already prepared
cluster. `locals.tf` supplies a complete release profile to each component; `main.tf` sets every chart's
identity and demonstrates value layers, account mappings, and regular, sensitive, and write-only
overrides. Component settings override `release_defaults`; use null to inherit those shared settings.

For a new cluster, use the [staged example](../staged). This full configuration assumes the issuer,
CRDs, public trust ConfigMap, and CA material already exist. It is not a single-state bootstrap recipe.
If releases are already managed elsewhere, keep their state ownership there or deliberately migrate it
before applying this configuration. Do not create two owners for the same release.

Supply cluster-specific `cilium_values`, a Ready `issuer_name` in `istio-system`, the
`root_ca_config_map` in `cert-manager`, and the two example secret values. The in-cluster CA consumes
pre-provisioned configuration and signing material as described in the staged example. Its private
root key is never passed through these inputs. This example installs no downstream workloads.

Set `istio_mode` to `sidecar` or `ambient`. Both use CNI here; only ambient creates ztunnel.
For an external CSR service, disable `enable_istio_csr` and set `istio.csr_address` to its endpoint.
For an existing base release, set `enable_istio_base = false` and `istio.manage_base = false`.
These are alternative ownership models, not toggles for temporarily skipping managed releases.

The optional repository credentials/TLS files default to null for the public chart sources.
Provenance verification is off; enable it with a matching keyring only for signed charts.
The `cat -` post-renderer leaves manifests unchanged and requires `cat` on PATH. Set `postrender = null`
to omit it. Resetting values and reusing historical values are alternatives; this example resets.
Replacement, forced updates, adoption, and upgrade-install are explicitly disabled.

Sensitive values remain in state. Write-only values are ephemeral Terraform inputs, but Helm and
chart-created Secrets may retain them in Kubernetes. Increment `write_only_revision` when changing
`write_only_value`. Keep all actual credentials out of version control.

## Running the example

Supply the inputs in `variables.tf`, then run `terraform init`, `terraform plan`, and `terraform apply`.
Connection settings are in `versions.tf`. See the [module README](../../README.md) for ownership and
lifecycle behavior and the [full configuration example](configuration) for custom resources.
