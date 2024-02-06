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

# ---------------------------------------------------
# Environment
# ---------------------------------------------------
data "confluent_environment" "cmprod-dr" {
  id = var.environment_id
}

# ---------------------------------------------------
# Create Dedicated Cluster in Environment
# ---------------------------------------------------
resource "confluent_kafka_cluster" "dedicated" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.csp
  region       = var.region
  dedicated {
    cku = 1
  }
  environment {
    id = data.confluent_environment.cmprod-dr.id
  }
}

# ---------------------------------------------------
# Use Service Accounts: cmapp-manager
# 'app-manager' service account is required in this configuration to create 'cmorders' topic and grant ACLs
# ---------------------------------------------------
resource "confluent_role_binding" "cmapp-manager-kafka-cluster-admin" {
  principal   = "User:${var.cmapp_manager_id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.dedicated.rbac_crn
  depends_on = [
    confluent_kafka_cluster.dedicated
  ]
}
resource "confluent_api_key" "cmapp-manager-kafka-api-key" {
  display_name = "cmapp-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-manager' service account"
  owner {
    id          = "${var.cmapp_manager_id}"
    api_version = "${var.cmapp_manager_api_version}"
    kind        = "${var.cmapp_manager_kind}"
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.cmprod-dr.id
    }
  }
}

# ---------------------------------------------------
# Create Keys for existing Service Accounts: cmapp-consumer
# ---------------------------------------------------
resource "confluent_api_key" "cmapp-consumer-kafka-api-key" {
  display_name = "cmapp-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-consumer' service account"
  owner {
    id          = "${var.cmapp_consumer_id}"
    api_version = "${var.cmapp_consumer_api_version}"
    kind        = "${var.cmapp_consumer_kind}"
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.cmprod-dr.id
    }
  }
  depends_on = [
    confluent_role_binding.cmapp-manager-kafka-cluster-admin
  ]
}

# ---------------------------------------------------
# Create Keys for Service Accounts: cmapp-producer
# ---------------------------------------------------
resource "confluent_api_key" "cmapp-producer-kafka-api-key" {
  display_name = "cmapp-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-producer' service account"
  owner {
    id          = "${var.cmapp_producer_id}"
    api_version = "${var.cmapp_producer_api_version}"
    kind        = "${var.cmapp_producer_kind}"
  }

  managed_resource {
    id          = confluent_kafka_cluster.dedicated.id
    api_version = confluent_kafka_cluster.dedicated.api_version
    kind        = confluent_kafka_cluster.dedicated.kind

    environment {
      id = data.confluent_environment.cmprod-dr.id
    }
  }
}

# ---------------------------------------------------------------
# Run Local Script for create properties files and start clients secrets
# ----------------------------------------------------------------
resource "null_resource" "properties" {
  depends_on = [
    data.confluent_environment.cmprod-dr,
    confluent_kafka_cluster.dedicated,
    confluent_api_key.cmapp-manager-kafka-api-key,
    confluent_api_key.cmapp-producer-kafka-api-key,
    confluent_api_key.cmapp-consumer-kafka-api-key,
  ]
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./00_create_client.properties.sh ${confluent_api_key.cmapp-consumer-kafka-api-key.id} ${confluent_api_key.cmapp-consumer-kafka-api-key.secret} ${confluent_api_key.cmapp-producer-kafka-api-key.id} ${confluent_api_key.cmapp-producer-kafka-api-key.secret} ${resource.confluent_kafka_cluster.dedicated.bootstrap_endpoint} ${var.consumer_group} ${var.cmapp_manager_id} ${var.cmapp_consumer_id} ${var.cmapp_producer_id} ${var.source_envid} ${var.cluster_source_id} ${data.confluent_environment.cmprod-dr.id} ${confluent_kafka_cluster.dedicated.id}"
  }

#./00_create_client.properties.sh 
#${confluent_api_key.cmapp-consumer-kafka-api-key.id} 
#${confluent_api_key.cmapp-consumer-kafka-api-key.secret} 
#${confluent_api_key.cmapp-producer-kafka-api-key.id} 
#${confluent_api_key.cmapp-producer-kafka-api-key.secret} 
#${resource.confluent_kafka_cluster.dedicated.bootstrap_endpoint} 
#${var.consumer_group} 
#${var.cmapp_manager_id} 
#${var.cmapp_consumer_id} 
#${var.cmapp_producer_id} 
#${var.source_envid} 
#${var.cluster_source_id} 
#${data.confluent_environment.cmprod-dr.id} 
#${confluent_kafka_cluster.dedicated.id}

  #provisioner "local-exec" {
  #  command = "./01_destroy.sh"
  #  when = destroy
  #}
}