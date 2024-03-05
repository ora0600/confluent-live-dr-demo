output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.cmprod.id}

  Service Account with EnvironmentAdmin and AccountAdmin roles and its Cloud API Key (API Keys inherit the permissions granted to the owner):

  ${confluent_service_account.cmenv-drmanager.display_name}:                     ${confluent_service_account.cmenv-drmanager.id}
  ${confluent_service_account.cmenv-drmanager.display_name}'s Cloud API Key:     "${confluent_api_key.cmenv-drmanager-cloud-api-key.id}"
  ${confluent_service_account.cmenv-drmanager.display_name}'s Cloud API Secret:  "${confluent_api_key.cmenv-drmanager-cloud-api-key.secret}"

  Please execute the following:
  source env-vars
  and then switch to 02-env-admin-product-team
  cd ../02-env-admin-product-team
  and create the cloud cluster resources for the DR design setup
  terraform apply --auto-approve
  EOT

  sensitive = true
}

output "envid" {
  value = confluent_environment.cmprod.id
}

output "key" {
  value = confluent_api_key.cmenv-drmanager-cloud-api-key.id
}

output "secret" {
  value = confluent_api_key.cmenv-drmanager-cloud-api-key.secret
  sensitive = true
}
