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
# Create Schema Registry in Environment
# ---------------------------------------------------
data "confluent_schema_registry_region" "setup" {
  cloud   = var.csp
  region  = var.region
  package = var.sr_package
}

resource "confluent_schema_registry_cluster" "setup" {
  package = data.confluent_schema_registry_region.setup.package

  environment {
    id = data.confluent_environment.cmprod-dr.id
  }

  region {
    id = data.confluent_schema_registry_region.setup.id
  }
}

# ---------------------------------------------------
# Create Basic Cluster in Environment
# ---------------------------------------------------
resource "confluent_kafka_cluster" "basic" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.csp
  region       = var.region
  basic {}
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
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
  depends_on = [
    confluent_kafka_cluster.basic
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
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.cmprod-dr.id
    }
  }
}

# ---------------------------------------------------
# Create Topic cmorder as 'cmapp-manager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmorders" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "cmorders"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
   key    = confluent_api_key.cmapp-manager-kafka-api-key.id
   secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
  depends_on = [
    confluent_api_key.cmapp-manager-kafka-api-key,
    confluent_kafka_cluster.basic,
    confluent_role_binding.cmapp-manager-kafka-cluster-admin
  ]
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
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

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
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.cmprod-dr.id
    }
  }
}

# ---------------------------------------------------
# Create ACL for Service Accounts: cmapp-producer
# ---------------------------------------------------
resource "confluent_kafka_acl" "cmapp-producer-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmorders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${var.cmapp_producer_id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}


# ---------------------------------------------------
# Create ACL for Service Accounts: cmapp-consumer
# ---------------------------------------------------
resource "confluent_kafka_acl" "cmapp-consumer-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmorders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${var.cmapp_consumer_id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-consumer-read-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "GROUP"
  resource_name = var.consumer_group
  pattern_type  = "PREFIXED"
  principal     = "User:${var.cmapp_consumer_id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

# ---------------------------------------------------------------
# Run Local Script for create properties files and start clients secrets
# ----------------------------------------------------------------
resource "null_resource" "properties" {
  depends_on = [
    data.confluent_environment.cmprod-dr,
    confluent_kafka_cluster.basic,
    confluent_api_key.cmapp-manager-kafka-api-key,
    confluent_api_key.cmapp-producer-kafka-api-key,
    confluent_api_key.cmapp-consumer-kafka-api-key,
  ]
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./00_create_client.properties.sh ${confluent_api_key.cmapp-consumer-kafka-api-key.id} ${confluent_api_key.cmapp-consumer-kafka-api-key.secret} ${confluent_api_key.cmapp-producer-kafka-api-key.id} ${confluent_api_key.cmapp-producer-kafka-api-key.secret} ${resource.confluent_kafka_cluster.basic.bootstrap_endpoint} ${var.consumer_group} ${var.cmapp_manager_id} ${var.cmapp_consumer_id} ${var.cmapp_producer_id}"
  }
}