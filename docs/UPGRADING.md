# Upgrading

This is the initial foundation implementation. Publish the release wrapper v2.0.0 to the Terraform
Registry before initializing or publishing foundation. Its dependency is deliberately pinned so a
wrapper update is reviewed together with the generated release settings.

Chart versions are pinned and tracked by Renovate, with one shared version for Istio's coordinated
components. Review each chart's upgrade notes and supported Kubernetes versions. Helm provider
compatibility does not establish compatibility for every chart or cluster version.

Run native tests and chart rendering after changing versions or integration values. Check both sidecar
and ambient modes, issuer scopes, CRDs, and controller RBAC. Run live acceptance in a disposable cluster
before production upgrades, including trust propagation and certificate renewal.

CRD upgrades/removal may require explicit upstream procedures. Preserve PKI and storage backups;
uninstalling a release is not a complete reset of Kubernetes CRDs or retained persistent volumes.
Never disable one Terraform state's releases merely to run the next installation stage.

Formr records provider/resource schema inventory, not arbitrary chart values or runtime correctness.
The root delegates resources to the release module; use its report for Helm attribute coverage. The
configuration submodule report documents the Kubernetes resources it actually uses. Not every generic
Kubernetes manifest operation is exposed: these are focused issuer and bootstrap interfaces.
Regenerate both reports when upgrading providers or changing the module interfaces.

## Current Formr limitation

Formr currently reports remote module sources as errors, even if Terraform has installed them.
The root report therefore remains incomplete and its default policy check fails. Do not rewrite the
report to claim full coverage or vendor the release module solely to avoid this diagnostic. Its Helm
interface is covered by the release wrapper's own report and tests; foundation's tests exercise its
release settings and generated integration values. Configuration-submodule inventory checks pass.

The initial root report was generated with `--schema-file` from a Formr snapshot of Helm 3.3.0 and
Kubernetes 3.3.0 acquired with Terraform 1.16.5. That temporary snapshot is not shipped in the module.
After the wrapper is published, normal `formr schema . -o docs/SCHEMA.md` can acquire provider schemas
in place, but still reports incomplete inventory until remote-source traversal is supported.

## Shared defaults and value conveniences

The existing operational defaults remain unchanged. Component nulls for fields in `release_defaults`
now inherit the shared value; component false/zero values remain explicit overrides. `values_object`
and mapped account settings are optional. Duplicate exact paths across `set*` collections now fail
validation instead of relying on provider iteration order. See the README for value-layer precedence.

The cert-manager identity used by step-issuer RBAC is derived from the controller's convenience inputs
unless explicitly set in `pki`. Ztunnel convenience names also update ambient CSR trust. If an existing
configuration changes identities through raw values, set the corresponding explicit integration fields
as well. Review account replacement and IAM association changes before applying renamed identities.
