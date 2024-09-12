################################################################################
# Encryption Key Data Sources
################################################################################
data "google_kms_key_ring" "my_key_ring" {
  name     = "antm-default-keyring-${var.location}"
  location = var.location
  project  = var.project_id
}

data "google_kms_crypto_key" "my_crypto_key" {
  name     = var.crypto_key
  key_ring = data.google_kms_key_ring.my_key_ring.id
}

################################################################################
# VPC Serverless Access Connector
################################################################################
# Obtain the Network Host Project for the particular Service Project
data "google_projects" "my-org-projects" {
  filter = "name:${local.buname}* parent.type:folder"
}

data "google_vpc_access_connector" "connector" {
  name    = var.vpc_access_connector
  project = element(local.nethost_project, 1)
}

################################################################################
# Cloud Run Resource
################################################################################

locals {
  tfmodule_name                                       = "terraform-google-cloud-run-service"
  tfmodule_version                                    = "0-0-2"
  tfmodule_info                                       = "${local.tfmodule_name}_${local.tfmodule_version}"
  buname                                              = element(split("-", "${var.project_id}"), 0)
  nethost_project                                     = [for nethostproj in data.google_projects.my-org-projects.projects[*].project_id : nethostproj if length(regexall("non-prod-network-host", nethostproj)) > 0 || length(regexall("prod-network-host", nethostproj)) > 0]
  ingress_service_annotation                          = { "run.googleapis.com/ingress" = var.ingress }
  run_description_service_annotation                  = var.run_description != "" ? { "run.googleapis.com/description" = var.run_description } : { "run.googleapis.com/description" = "The Google Cloud Run Service Instance for ${var.name}" }
  cmek_template_annotation                            = { "run.googleapis.com/encryption-key" = data.google_kms_crypto_key.my_crypto_key.id }
  encryption_key_shutdown_hours_template_annotation   = { "run.googleapis.com/encryption-key-shutdown-hours" = "1" }
  vpc_access_connector_template_annotation            = { "run.googleapis.com/vpc-access-connector" = data.google_vpc_access_connector.connector.id }
  maxscale_template_annotation                        = var.maxscale != null ? { "autoscaling.knative.dev/maxScale" = var.maxscale } : { "autoscaling.knative.dev/maxScale" = "5" }
  minscale_template_annotation                        = var.minscale != null ? { "autoscaling.knative.dev/minScale" = var.minscale } : { "autoscaling.knative.dev/minScale" = "0" }
  vpc_access_egress_template_annotation               = { "run.googleapis.com/vpc-access-egress" = var.vpc_access_egress }
  cloudsql_instances_template_annotation              = var.cloudsql_instances != "" ? { "run.googleapis.com/cloudsql-instances" = var.cloudsql_instances } : {}
  execution_environment_template_annotation           = var.execution_environment != "" ? { "run.googleapis.com/execution-environment" = var.execution_environment } : { "run.googleapis.com/execution-environment" = "gen2" }
  post_key_revocation_action_type_template_annotation = var.post_key_revocation_action_type != "" ? { "run.googleapis.com/post-key-revocation-action-type" = var.post_key_revocation_action_type } : { "run.googleapis.com/post-key-revocation-action-type" = "shut-down" }

  template_annotations = merge(
    var.additional_template_annotations,
    local.cmek_template_annotation,
    local.maxscale_template_annotation,
    local.minscale_template_annotation,
    local.cloudsql_instances_template_annotation,
    local.encryption_key_shutdown_hours_template_annotation,
    local.execution_environment_template_annotation,
    local.post_key_revocation_action_type_template_annotation,
    local.vpc_access_connector_template_annotation,
    local.vpc_access_egress_template_annotation
  )

  service_annotations = merge(
    var.additional_service_annotations,
    local.ingress_service_annotation
  )
}

output "tfmodule_info" {
  value = local.tfmodule_info
}

resource "google_cloud_run_service" "run_service" {
  name                       = var.name
  location                   = var.location
  autogenerate_revision_name = var.autogenerate_revision_name
  template {
    spec {
      containers {
        image   = var.image
        args    = try(var.args, null)
        command = try(var.command, null)

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.value["name"]
            value = env.value["value"]
          }
        }

        dynamic "ports" {
          for_each = var.ports == null ? [] : var.ports
          content {
            name           = lookup(ports.value, "name", null)
            container_port = lookup(ports.value, "container_port", null)
          }
        }

        dynamic "volume_mounts" {
          for_each = var.volume_mounts == null ? [] : var.volume_mounts
          content {
            name       = lookup(volume_mounts.value, "name")
            mount_path = lookup(volume_mounts.value, "mount_path")
          }
        }

        dynamic "startup_probe" {
          for_each = var.startup_probe == null ? [] : var.startup_probe
          content {
            initial_delay_seconds = lookup(startup_probe.value, "initial_delay_seconds")
            failure_threshold     = lookup(startup_probe.value, "failure_threshold")
            timeout_seconds       = lookup(startup_probe.value, "timeout_seconds")
            period_seconds        = lookup(startup_probe.value, "period_seconds")

            dynamic "http_get" {
              for_each = lookup(startup_probe.value, "http_get", [])
              content {
                path = lookup(http_get.value, "path", null)
                port = lookup(http_get.value, "port", null)

                dynamic "http_headers" {
                  for_each = lookup(startup_probe.value, "http_headers", [])
                  content {
                    name  = lookup(http_headers.value, "name", null)
                    value = lookup(http_headers.value, "value", null)
                  }
                }
              }
            }

            dynamic "tcp_socket" {
              for_each = lookup(startup_probe.value, "tcp_socket", [])
              content {
                port = lookup(tcp_socket.value, "port", null)
              }
            }

            dynamic "grpc" {
              for_each = lookup(startup_probe.value, "grpc", [])
              content {
                port    = lookup(grpc.value, "port", null)
                service = lookup(grpc.value, "service", null)
              }
            }
          }
        }

        dynamic "liveness_probe" {
          for_each = var.liveness_probe == null ? [] : var.liveness_probe
          content {
            initial_delay_seconds = lookup(liveness_probe.value, "initial_delay_seconds")
            failure_threshold     = lookup(liveness_probe.value, "failure_threshold")
            timeout_seconds       = lookup(liveness_probe.value, "timeout_seconds")
            period_seconds        = lookup(liveness_probe.value, "period_seconds")

            dynamic "http_get" {
              for_each = lookup(liveness_probe.value, "http_get", [])
              content {
                path = lookup(http_get.value, "path", null)
                port = lookup(http_get.value, "port", null)

                dynamic "http_headers" {
                  for_each = lookup(liveness_probe.value, "http_headers", [])
                  content {
                    name  = lookup(http_headers.value, "name", null)
                    value = lookup(http_headers.value, "value", null)
                  }
                }
              }
            }

            dynamic "grpc" {
              for_each = lookup(liveness_probe.value, "grpc", [])
              content {
                port    = lookup(grpc.value, "port", null)
                service = lookup(grpc.value, "service", null)
              }
            }
          }
        }

        resources {
          limits   = try(var.limits, null)
          requests = try(var.requests, null)
        }
      } //This closes containers

      dynamic "volumes" {
        for_each = var.volumes == null ? [] : var.volumes
        content {
          name = lookup(volumes.value, "name")
          dynamic "secret" {
            for_each = volumes.value.secret == null ? [] : volumes.value.secret
            content {
              secret_name  = lookup(secret.value, "secret_name")
              default_mode = lookup(secret.value, "default_mode", null)
              dynamic "items" {
                for_each = secret.value.items == null ? [] : secret.value.items
                content {
                  key  = lookup(items.value, "key")
                  path = lookup(items.value, "path")
                  mode = lookup(items.value, "mode", null)
                }
              }
            }
          }
        }
      }

      container_concurrency = var.container_concurrency
      timeout_seconds       = var.timeout_seconds
      service_account_name  = var.service_account_name
    } //This closes spec

    #Template Metadata: Includes Template Annotations
    metadata {
      labels      = try(var.template_labels, null)
      namespace   = var.project_id
      annotations = local.template_annotations
      name        = var.autogenerate_revision_name == true ? null : "${var.traffic.0.revision_name}"
    }
  } //This closes template 

  #Resource Metadata: Includes Service Annotations
  metadata {
    labels      = merge(var.labels, { "provisioned-by" : local.tfmodule_info })
    namespace   = var.project_id
    annotations = local.service_annotations
  }

  dynamic "traffic" {
    for_each = var.traffic
    content {
      percent         = lookup(traffic.value, "percent", 100)
      latest_revision = lookup(traffic.value, "latest_revision", null)
      revision_name   = lookup(traffic.value, "latest_revision") ? null : lookup(traffic.value, "revision_name")
      tag             = lookup(traffic.value, "tag", null)
    }
  }

  lifecycle {
    ignore_changes = [
      metadata[0].annotations["client.knative.dev/user-image"],
      metadata[0].annotations["run.googleapis.com/client-name"],
      metadata[0].annotations["run.googleapis.com/client-version"],
      metadata[0].annotations["run.googleapis.com/operation-id"],
      template[0].metadata[0].annotations["client.knative.dev/user-image"],
      template[0].metadata[0].annotations["run.googleapis.com/client-name"],
      template[0].metadata[0].annotations["run.googleapis.com/client-version"],
      template[0].metadata[0].namespace,
      metadata[0].namespace
    ]
  }

  timeouts {
    create = "${var.create_timeout}m"
    delete = "${var.delete_timeout}m"
    update = "${var.update_timeout}m"
  }
}
