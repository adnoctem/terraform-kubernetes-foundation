# Full foundation configuration example

This is an independent Terraform root/state. It shows every configuration-submodule input and nested
field after the controller CRDs exist. Do not call it from the parent full example in the same plan.

Supply the existing CA endpoint, independently verified public root PEM, and provisioner name/key ID.
The provisioner Secret must already exist in `istio-system`. Both namespaced and cluster-scoped issuers
reference it; their namespace settings demonstrate the two mutually exclusive models.

The `cert-manager`, `istio-system`, and (if bootstrap is enabled) `argocd` namespaces already exist.
This state creates only `platform-trust`, publishes public certificates, and configures issuers.
Supply `bootstrap_application_spec` only to manage an explicit GitOps bootstrap object. The example
waits for its Healthy status; set `wait_fields = {}` to omit that wait. Finalizers are empty to avoid
opting into cascading deletion. Do not include Terraform-owned foundation resources in its spec.

Run `terraform init`, `terraform plan`, and `terraform apply` after the prerequisites are ready.
See [staged bootstrap](../../staged) for installation order and the
[configuration module](../../../modules/configuration) for lifecycle notes.
