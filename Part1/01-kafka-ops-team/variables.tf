variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID) with OrganizationAdmin permissions"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "prod_environment_name" {
  description = "Name Confluent Cloud Environment"
  type        = string
  default     = "cmprod"
}

variable "dr_environment_name" {
  description = "Name Confluent Cloud Environment"
  type        = string
  default     = "cmprod-dr"
}
