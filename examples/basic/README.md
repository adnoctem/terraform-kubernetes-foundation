# Basic controllers

Install cert-manager with two controller replicas and its CRDs. Configure kubeconfig/context inputs,
then run `terraform init`, `terraform plan`, and `terraform apply`. The release wrapper dependency must
already be published. This does not provision a Kubernetes cluster.

This example uses shared release defaults, native HCL chart values, and the catalog's controller
account mapping. The annotation is illustrative metadata and grants no cloud permissions.
