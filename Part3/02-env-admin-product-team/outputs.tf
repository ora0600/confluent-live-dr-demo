output "resource-ids" {
  value = <<-EOT
  Primary Kafka Cluster ID: ${confluent_kafka_cluster.primary.id}
  Secondary Kafka Cluster ID: ${confluent_kafka_cluster.secondary.id}
  Kafka topic name: ${confluent_kafka_topic.cmorders.topic_name}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.cmapp-drmanager.display_name}:                     ${confluent_service_account.cmapp-drmanager.id}
  ${confluent_service_account.cmapp-drmanager.display_name}'s Kafka API Key:     "${confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id}"
  ${confluent_service_account.cmapp-drmanager.display_name}'s Kafka API Secret:  "${confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret}"
  ${confluent_service_account.cmapp-drmanager.display_name}'s Kafka API Key (secondary):     "${confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id}"
  ${confluent_service_account.cmapp-drmanager.display_name}'s Kafka API Secret(secondary):  "${confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret}"

  ${confluent_service_account.cmapp-drproducer.display_name}:                    ${confluent_service_account.cmapp-drproducer.id}
  ${confluent_service_account.cmapp-drproducer.display_name}'s Kafka API Key:    "${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.id}"
  ${confluent_service_account.cmapp-drproducer.display_name}'s Kafka API Secret: "${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.secret}"
  ${confluent_service_account.cmapp-drproducer.display_name}'s Kafka API Key (secondary):    "${confluent_api_key.cmapp-drproducer-secondary-kafka-api-key.id}"
  ${confluent_service_account.cmapp-drproducer.display_name}'s Kafka API Secret (secondary): "${confluent_api_key.cmapp-drproducer-secondary-kafka-api-key.secret}"

  ${confluent_service_account.cmapp-drconsumer.display_name}:                    ${confluent_service_account.cmapp-drconsumer.id}
  ${confluent_service_account.cmapp-drconsumer.display_name}'s Kafka API Key:    "${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.id}"
  ${confluent_service_account.cmapp-drconsumer.display_name}'s Kafka API Secret: "${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.secret}"
  ${confluent_service_account.cmapp-drconsumer.display_name}'s Kafka API Key (secondary):    "${confluent_api_key.cmapp-drconsumer-secondary-kafka-api-key.id}"
  ${confluent_service_account.cmapp-drconsumer.display_name}'s Kafka API Secret(secondary): "${confluent_api_key.cmapp-drconsumer-secondary-kafka-api-key.secret}"

  In order to use the Confluent CLI v2 to produce and consume messages from topic '${confluent_kafka_topic.cmorders.topic_name}' using Kafka API Keys
  of ${confluent_service_account.cmapp-drproducer.display_name} and ${confluent_service_account.cmapp-drconsumer.display_name} service accounts
  run the following commands:

  # 1. Log in to Confluent Cloud
  $ confluent login

  # 2. Produce key-value records to topic '${confluent_kafka_topic.cmorders.topic_name}' by using ${confluent_service_account.cmapp-drproducer.display_name}'s Kafka API Key
  $ confluent kafka topic produce ${confluent_kafka_topic.cmorders.topic_name} --environment ${var.environment_id} --cluster ${confluent_kafka_cluster.primary.id} --api-key "${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.id}" --api-secret "${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.secret}"
  # Enter a few records and then press 'Ctrl-C' when you're done.
  # Sample records:
  # {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}
  # {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}
  # {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}

  # 3. Consume records from topic '${confluent_kafka_topic.cmorders.topic_name}' by using ${confluent_service_account.cmapp-drconsumer.display_name}'s Kafka API Key
  $ confluent kafka topic consume ${confluent_kafka_topic.cmorders.topic_name} --from-beginning --environment ${var.environment_id} --cluster ${confluent_kafka_cluster.primary.id} --api-key "${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.id}" --api-secret "${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.secret}"
  # When you are done, press 'Ctrl-C'.
  EOT

  sensitive = true
}

output "cc_kafka_cluster_bootsrap" {
  description = "CC Kafka Cluster ID"
  value       = confluent_kafka_cluster.primary.bootstrap_endpoint
}

output "consumer_group" {
  value = var.consumer_group
}

output "consumer_key" {
  value = confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.id
}

output "consumer_secret" {
  value = confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.secret
  sensitive = true
}

output "producer_key" {
  value = confluent_api_key.cmapp-drproducer-primary-kafka-api-key.id
}

output "producer_secret" {
  value = confluent_api_key.cmapp-drproducer-primary-kafka-api-key.secret
  sensitive = true
}