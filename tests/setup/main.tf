variable "location" {
  type = string
}

variable "crypto_key" {
  type = string
}

variable "key_ring_name" {
  type        = string
  description = "(Optional) The name of the key ring to use. If blank, name will be inferred."
}

## key_rings cannot be deleted, so we'll have to use a stationary one named 'tf-integration-test'
## this is to prevent creating a new key_ring for each test
data "google_kms_key_ring" "setup" {
  name     = var.key_ring_name
  location = var.location
}

## create a temp key for testing. This key will remain for 24h, then it is automatically deleted.

resource "google_kms_crypto_key" "setup" {
  name                       = var.crypto_key
  key_ring                   = data.google_kms_key_ring.setup.id
  destroy_scheduled_duration = "86400s"
  #checkov:skip=CKV_GCP_82:Test keys are allowed to be deleted
  #checkov:skip=CKV_GCP_43:Test keys don't need to be rotated
}

data "google_project" "project" {}

resource "google_kms_crypto_key_iam_binding" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.setup.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:service-${data.google_project.project.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com",
  ]
}

resource "google_vpc_access_connector" "connector" {
  name          = "vpc-con"
  ip_cidr_range = "10.8.0.0/28"
  network       = "default"
  min_instances = 2
  max_instances = 3
  region        = var.location
}

output "test_key_name" {
  value = google_kms_crypto_key.setup.name
}

output "test_vpc_connector_name" {
  value = google_vpc_access_connector.connector.name
}
