variable "confluent_cloud_api_key" {
  description = "Confluent Cloud API Key (also referred as Cloud API ID) with EnvironmentAdmin permissions provided by Kafka Ops team"
  type        = string
}

variable "confluent_cloud_api_secret" {
  description = "Confluent Cloud API Secret"
  type        = string
  sensitive   = true
}

variable "environment_id" {
  description = "The ID of the managed environment"
  type        = string
}

variable "csp" {
  description = "Cloud Provicer"
  type        = string
  default     = "GCP"
}

variable "region" {
  description = "Region of CSP"
  type        = string
  default     = "europe-west3"
}

variable "sr_package" {
  description = "Package of Schema Registry"
  type        = string
  default     = "ESSENTIALS"
}

variable "cluster_name" {
  description = "Name of Kafka Cluster"
  type        = string
  default     = "dr_cmprod_cluster"
}

variable "consumer_group" {
  description = "Name of Consumergroup"
  type        = string
  default     = "cmgroup"
}

variable "cmapp_manager_id" {
  description = "ID of Service Account cmapp-manager"
  type        = string
}
variable "cmapp_manager_kind" {
  description = "KIND of Service Account cmapp-manager"
  type        = string
}
variable "cmapp_manager_api_version" {
  description = "API Version of Service Account cmapp-manager"
  type        = string
}

variable "cmapp_consumer_id" {
  description = "ID of Service Account cmapp-consumer_id"
  type        = string
}
variable "cmapp_consumer_kind" {
  description = "KIND of Service Account cmapp-consumer_id"
  type        = string
}
variable "cmapp_consumer_api_version" {
  description = "API VErsion of Service Account cmapp-consumer_id"
  type        = string
}

variable "cmapp_producer_id" {
  description = "ID of Service Account cmapp-producer"
  type        = string
}
variable "cmapp_producer_kind" {
  description = "Kind of Service Account cmapp-producer"
  type        = string
}
variable "cmapp_producer_api_version" {
  description = "API Version of Service Account cmapp-producer"
  type        = string
}
