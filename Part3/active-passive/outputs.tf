output "resource-ids" {
  value = <<-EOT
  Kafka Cluster ID: ${confluent_kafka_cluster.dedicated.id}
  Kafka topic name: ${confluent_kafka_topic.test.topic_name}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  cmapp-manager: ${var.cmapp_manager_id}
  cmapp-manager's Kafka API Key:     "${confluent_api_key.cmapp-manager-kafka-api-key.id}"
  cmapp-manager's Kafka API Secret:  "${confluent_api_key.cmapp-manager-kafka-api-key.secret}"

  cmapp_producer: ${var.cmapp_producer_id}
  cmapp_producer's Kafka API Key:    "${confluent_api_key.cmapp-producer-kafka-api-key.id}"
  cmapp_producer's Kafka API Secret: "${confluent_api_key.cmapp-producer-kafka-api-key.secret}"

  cmapp_consumer: ${var.cmapp_consumer_id}
  cmapp_consumer's Kafka API Key:    "${confluent_api_key.cmapp-consumer-kafka-api-key.id}"
  cmapp_consumer's Kafka API Secret: "${confluent_api_key.cmapp-consumer-kafka-api-key.secret}"

  In order to use the Confluent CLI v2 to produce and consume messages from topic '${confluent_kafka_topic.test.topic_name}' using Kafka API Keys
  of cmapp-producer and cmapp-consumer service accounts
  run the following commands:

  # 1. Log in to Confluent Cloud
  $ confluent login

  # 2. Consume records from topic '${confluent_kafka_topic.test.topic_name}' by using cmapp-consumer's Kafka API Key
  $ confluent kafka topic consume ${confluent_kafka_topic.test.topic_name} --from-beginning --environment ${data.confluent_environment.cmprod-dr.id} --cluster ${confluent_kafka_cluster.dedicated.id} --api-key "${confluent_api_key.cmapp-consumer-kafka-api-key.id}" --api-secret "${confluent_api_key.cmapp-consumer-kafka-api-key.secret}"
  # When you are done, press 'Ctrl-C'.
  EOT

  sensitive = true
}

output "cc_kafka_cluster_bootsrap" {
  description = "CC Kafka Cluster ID"
  value       = resource.confluent_kafka_cluster.dedicated.bootstrap_endpoint
}

output "consumer_group" {
  value = var.consumer_group
}

output "consumer_key" {
  value = confluent_api_key.cmapp-consumer-kafka-api-key.id
}

output "consumer_secret" {
  value = confluent_api_key.cmapp-consumer-kafka-api-key.secret
  sensitive = true
}

output "producer_key" {
  value = confluent_api_key.cmapp-producer-kafka-api-key.id
}

output "producer_secret" {
  value = confluent_api_key.cmapp-producer-kafka-api-key.secret
  sensitive = true
}

output "manager_key" {
  value = confluent_api_key.cmapp-manager-kafka-api-key.id
}

output "manager_secret" {
  value = confluent_api_key.cmapp-manager-kafka-api-key.secret
  sensitive = true
}

output "appmanid" {
  value = var.cmapp_manager_id
}

output "consumerid" {
  value = var.cmapp_consumer_id
}

output "producerid" {
  value = var.cmapp_producer_id
}