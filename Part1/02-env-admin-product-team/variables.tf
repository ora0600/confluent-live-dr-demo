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
  default     = "AWS"
}

variable "region" {
  description = "Region of CSP"
  type        = string
  default     = "eu-central-1"
}

variable "sr_package" {
  description = "Package of Schema Registry"
  type        = string
  default     = "ESSENTIALS"
}

variable "cluster_name" {
  description = "Name of Kafka Cluster"
  type        = string
  default     = "cmprod_cluster"
}

variable "consumer_group" {
  description = "Name of Consumergroup"
  type        = string
  default     = "cmgroup"
}