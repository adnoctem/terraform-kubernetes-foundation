mock_provider "helm" {}
run "computed_release_values" {
  command = plan
  module { source = "./tests/setup" }
  assert {
    condition     = output.keys == ["argocd"]
    error_message = "Computed release settings must not control module instance counts."
  }
}
