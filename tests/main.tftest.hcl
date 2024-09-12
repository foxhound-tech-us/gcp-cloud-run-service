provider "google" {}

variables {
  crypto_key    = "test-key-${split("-", uuid())[0]}"
  location      = "us-west1"
  repository_id = "my-artifact-repository-${split("-", uuid())[0]}"
  key_ring_name = "tf-integration-test"
}

run "setup" {
  ## create prerequisite resources
  module {
    source = "./tests/setup"
  }
}

run "module_test" {
  command = apply

  variables {
    crypto_key           = run.setup.test_key_name
    vpc_access_connector = run.setup.test_vpc_connector_name
    image                = "busybox"
    labels = ["test"]
  }

  assert {
    condition     = output.id != null
    error_message = "output.id cannot be null"
  }

  assert {
    condition     = output.status != null
    error_message = "output.status cannot be null"
  }
}
