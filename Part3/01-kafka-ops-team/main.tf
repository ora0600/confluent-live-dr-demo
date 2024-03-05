terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.61.0"
    }
  }
}

provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}

data "confluent_organization" "this" {}

resource "confluent_environment" "cmprod" {
  display_name = var.prod_environment_name
}

resource "confluent_service_account" "cmenv-drmanager" {
  display_name = "cmenv-drmanager"
  description  = "Service account to manage resources under 'cmprod-active'environment"
}

resource "confluent_role_binding" "cmenv-drmanager-env-admin-cmprod" {
  principal   = "User:${confluent_service_account.cmenv-drmanager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cmprod.resource_name
}

resource "confluent_role_binding" "cmenv-drmanager-account-admin" {
  principal   = "User:${confluent_service_account.cmenv-drmanager.id}"
  role_name   = "AccountAdmin"
  crn_pattern = data.confluent_organization.this.resource_name
}

resource "confluent_api_key" "cmenv-drmanager-cloud-api-key" {
  display_name = "cmenv-manager-cloud-api-key"
  description  = "Cloud API Key to be shared with Product team to manage resources under 'cmprod-active' environment"
  owner {
    id          = confluent_service_account.cmenv-drmanager.id
    api_version = confluent_service_account.cmenv-drmanager.api_version
    kind        = confluent_service_account.cmenv-drmanager.kind
  }

  depends_on = [
    confluent_environment.cmprod,
    confluent_service_account.cmenv-drmanager,
    confluent_role_binding.cmenv-drmanager-env-admin-cmprod,
    confluent_role_binding.cmenv-drmanager-account-admin
  ]
}

# ---------------------------------------------------------------
# Run Local Script for create env source file
# ----------------------------------------------------------------
resource "null_resource" "env-setup" {
  depends_on = [
    resource.confluent_environment.cmprod,
    resource.confluent_service_account.cmenv-drmanager,
    resource.confluent_api_key.cmenv-drmanager-cloud-api-key,
    resource.confluent_role_binding.cmenv-drmanager-account-admin
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./00_env-and-keys.sh ${confluent_environment.cmprod.id}  ${confluent_api_key.cmenv-drmanager-cloud-api-key.id} ${confluent_api_key.cmenv-drmanager-cloud-api-key.secret}"
  }

}
