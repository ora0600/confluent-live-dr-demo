output "resource-ids" {
  value = <<-EOT
  Environment ID:   ${confluent_environment.cmprod.id}

  Service Account with EnvironmentAdmin and AccountAdmin roles and its Cloud API Key (API Keys inherit the permissions granted to the owner):

  ${confluent_service_account.cmenv-manager.display_name}:                     ${confluent_service_account.cmenv-manager.id}
  ${confluent_service_account.cmenv-manager.display_name}'s Cloud API Key:     "${confluent_api_key.cmenv-manager-cloud-api-key.id}"
  ${confluent_service_account.cmenv-manager.display_name}'s Cloud API Secret:  "${confluent_api_key.cmenv-manager-cloud-api-key.secret}"

  Please execute the following:
  source env-vars
  and then switch to 02-env-admin-product-team
  cd ../02-env-admin-product-team
  and create the cloud resources
  terraform apply --auto-approve
  EOT

  sensitive = true
}

output "envid" {
  value = confluent_environment.cmprod.id
}

output "envid-dr" {
  value = confluent_environment.cmprod-dr.id
}

output "key" {
  value = confluent_api_key.cmenv-manager-cloud-api-key.id
}

output "secret" {
  value = confluent_api_key.cmenv-manager-cloud-api-key.secret
  sensitive = true
}
