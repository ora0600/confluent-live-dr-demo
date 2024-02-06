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

resource "confluent_environment" "cmprod-dr" {
  display_name = var.dr_environment_name
}


resource "confluent_service_account" "cmenv-manager" {
  display_name = "cmenv-manager"
  description  = "Service account to manage resources under 'cmprod' ND 'cmprod-dr' environment"
}

resource "confluent_role_binding" "cmenv-manager-env-admin-cmprod" {
  principal   = "User:${confluent_service_account.cmenv-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cmprod.resource_name
}

resource "confluent_role_binding" "cmenv-manager-env-admin-cmprod-dr" {
  principal   = "User:${confluent_service_account.cmenv-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.cmprod-dr.resource_name
}

resource "confluent_role_binding" "cmenv-manager-account-admin" {
  principal   = "User:${confluent_service_account.cmenv-manager.id}"
  role_name   = "AccountAdmin"
  crn_pattern = data.confluent_organization.this.resource_name
}

resource "confluent_api_key" "cmenv-manager-cloud-api-key" {
  display_name = "cmenv-manager-cloud-api-key"
  description  = "Cloud API Key to be shared with Product team to manage resources under 'cmprod' environment"
  owner {
    id          = confluent_service_account.cmenv-manager.id
    api_version = confluent_service_account.cmenv-manager.api_version
    kind        = confluent_service_account.cmenv-manager.kind
  }

  depends_on = [
    confluent_environment.cmprod,
    confluent_environment.cmprod-dr,
    confluent_service_account.cmenv-manager,
    confluent_role_binding.cmenv-manager-env-admin-cmprod,
    confluent_role_binding.cmenv-manager-env-admin-cmprod-dr,
    confluent_role_binding.cmenv-manager-account-admin
  ]
}

# ---------------------------------------------------------------
# Run Local Script for create env source file
# ----------------------------------------------------------------
resource "null_resource" "env-setup" {
  depends_on = [
    resource.confluent_environment.cmprod,
    resource.confluent_environment.cmprod-dr,
    resource.confluent_service_account.cmenv-manager,
    resource.confluent_api_key.cmenv-manager-cloud-api-key,
    resource.confluent_role_binding.cmenv-manager-env-admin-cmprod,
    resource.confluent_role_binding.cmenv-manager-account-admin
  ]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./00_env-and-keys.sh ${confluent_environment.cmprod.id} ${confluent_environment.cmprod-dr.id} ${confluent_api_key.cmenv-manager-cloud-api-key.id} ${confluent_api_key.cmenv-manager-cloud-api-key.secret}"
  }

}
