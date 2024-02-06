output "resource-ids" {
  value = <<-EOT
  Kafka Cluster ID: ${confluent_kafka_cluster.basic.id}
  Kafka topic name: ${confluent_kafka_topic.cmorders.topic_name}

  Service Accounts and their Kafka API Keys (API Keys inherit the permissions granted to the owner):
  ${confluent_service_account.cmapp-manager.display_name}:                     ${confluent_service_account.cmapp-manager.id}
  ${confluent_service_account.cmapp-manager.display_name}'s Kafka API Key:     "${confluent_api_key.cmapp-manager-kafka-api-key.id}"
  ${confluent_service_account.cmapp-manager.display_name}'s Kafka API Secret:  "${confluent_api_key.cmapp-manager-kafka-api-key.secret}"

  ${confluent_service_account.cmapp-producer.display_name}:                    ${confluent_service_account.cmapp-producer.id}
  ${confluent_service_account.cmapp-producer.display_name}'s Kafka API Key:    "${confluent_api_key.cmapp-producer-kafka-api-key.id}"
  ${confluent_service_account.cmapp-producer.display_name}'s Kafka API Secret: "${confluent_api_key.cmapp-producer-kafka-api-key.secret}"

  ${confluent_service_account.cmapp-consumer.display_name}:                    ${confluent_service_account.cmapp-consumer.id}
  ${confluent_service_account.cmapp-consumer.display_name}'s Kafka API Key:    "${confluent_api_key.cmapp-consumer-kafka-api-key.id}"
  ${confluent_service_account.cmapp-consumer.display_name}'s Kafka API Secret: "${confluent_api_key.cmapp-consumer-kafka-api-key.secret}"

  In order to use the Confluent CLI v2 to produce and consume messages from topic '${confluent_kafka_topic.cmorders.topic_name}' using Kafka API Keys
  of ${confluent_service_account.cmapp-producer.display_name} and ${confluent_service_account.cmapp-consumer.display_name} service accounts
  run the following commands:

  # 1. Log in to Confluent Cloud
  $ confluent login

  # 2. Produce key-value records to topic '${confluent_kafka_topic.cmorders.topic_name}' by using ${confluent_service_account.cmapp-producer.display_name}'s Kafka API Key
  $ confluent kafka topic produce ${confluent_kafka_topic.cmorders.topic_name} --environment ${data.confluent_environment.cmprod.id} --cluster ${confluent_kafka_cluster.basic.id} --api-key "${confluent_api_key.cmapp-producer-kafka-api-key.id}" --api-secret "${confluent_api_key.cmapp-producer-kafka-api-key.secret}"
  # Enter a few records and then press 'Ctrl-C' when you're done.
  # Sample records:
  # {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}
  # {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}
  # {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}

  # 3. Consume records from topic '${confluent_kafka_topic.cmorders.topic_name}' by using ${confluent_service_account.cmapp-consumer.display_name}'s Kafka API Key
  $ confluent kafka topic consume ${confluent_kafka_topic.cmorders.topic_name} --from-beginning --environment ${data.confluent_environment.cmprod.id} --cluster ${confluent_kafka_cluster.basic.id} --api-key "${confluent_api_key.cmapp-consumer-kafka-api-key.id}" --api-secret "${confluent_api_key.cmapp-consumer-kafka-api-key.secret}"
  # When you are done, press 'Ctrl-C'.
  EOT

  sensitive = true
}

output "cc_kafka_cluster_bootsrap" {
  description = "CC Kafka Cluster ID"
  value       = resource.confluent_kafka_cluster.basic.bootstrap_endpoint

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

output "appmanid" {
  value = confluent_service_account.cmapp-manager.id
}
output "appmanidkind" {
  value = confluent_service_account.cmapp-manager.kind
}
output "appmanidapiversion" {
  value = confluent_service_account.cmapp-manager.api_version
}

output "consumerid" {
  value = confluent_service_account.cmapp-consumer.id
}
output "consumeridkind" {
  value = confluent_service_account.cmapp-consumer.kind
}
output "consumeridapiversion" {
  value = confluent_service_account.cmapp-consumer.api_version
}

output "producerid" {
  value = confluent_service_account.cmapp-producer.id
}
output "produceridkind" {
  value = confluent_service_account.cmapp-producer.kind
}
output "produceridapiversion" {
  value = confluent_service_account.cmapp-producer.api_version
}