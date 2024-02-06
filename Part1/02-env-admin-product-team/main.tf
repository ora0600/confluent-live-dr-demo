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
data "confluent_environment" "cmprod" {
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
    id = data.confluent_environment.cmprod.id
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
    id = data.confluent_environment.cmprod.id
  }
}

# ---------------------------------------------------
# Create Service Accounts: cmapp-manager
# 'app-manager' service account is required in this configuration to create 'cmorders' topic and grant ACLs
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-manager" {
  display_name = "cmapp-manager"
  description  = "Service account to manage Kafka cluster"
}

resource "confluent_role_binding" "cmapp-manager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.cmapp-manager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.basic.rbac_crn
}

resource "confluent_api_key" "cmapp-manager-kafka-api-key" {
  display_name = "cmapp-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-manager' service account"
  owner {
    id          = confluent_service_account.cmapp-manager.id
    api_version = confluent_service_account.cmapp-manager.api_version
    kind        = confluent_service_account.cmapp-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }

  depends_on = [
    confluent_role_binding.cmapp-manager-kafka-cluster-admin
  ]
}

# ---------------------------------------------------
# Create Topic cmorders as 'cmapp-manager' service account
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
}

# ---------------------------------------------------
# Create Topic cmcustomers as 'cmapp-manager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "cmcustomers"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

# ---------------------------------------------------
# Create Topic cmproducts as 'cmapp-manager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  topic_name    = "cmproducts"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}


# ---------------------------------------------------
# Create Service Accounts: cmapp-consumer with API KEY
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-consumer" {
  display_name = "cmapp-consumer"
  description  = "Service account to consume from 'cmorders' topic of Kafka cluster"
}

resource "confluent_api_key" "cmapp-consumer-kafka-api-key" {
  display_name = "cmapp-consumer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-consumer' service account"
  owner {
    id          = confluent_service_account.cmapp-consumer.id
    api_version = confluent_service_account.cmapp-consumer.api_version
    kind        = confluent_service_account.cmapp-consumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }
}


# ---------------------------------------------------
# Create Service Accounts: cmapp-producer
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-producer" {
  display_name = "cmapp-producer"
  description  = "Service account to produce to 'cmorders' topic of Kafka cluster"
}

resource "confluent_api_key" "cmapp-producer-kafka-api-key" {
  display_name = "cmapp-producer-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-producer' service account"
  owner {
    id          = confluent_service_account.cmapp-producer.id
    api_version = confluent_service_account.cmapp-producer.api_version
    kind        = confluent_service_account.cmapp-producer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.basic.id
    api_version = confluent_kafka_cluster.basic.api_version
    kind        = confluent_kafka_cluster.basic.kind

    environment {
      id = data.confluent_environment.cmprod.id
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
  principal     = "User:${confluent_service_account.cmapp-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-producer-write-on-cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmcustomers.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-producer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-producer-write-on-cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmproducts.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-producer.id}"
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
  principal     = "User:${confluent_service_account.cmapp-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-consumer-read-on-cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmcustomers.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-consumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.basic.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-manager-kafka-api-key.id
    secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-consumer-read-on-cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.basic.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmproducts.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-consumer.id}"
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
  principal     = "User:${confluent_service_account.cmapp-consumer.id}"
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
# Run Local Script for create properties files and start clients
# ----------------------------------------------------------------
resource "null_resource" "properties" {
  depends_on = [
    data.confluent_environment.cmprod,
    confluent_kafka_cluster.basic,
    confluent_service_account.cmapp-manager,
    confluent_api_key.cmapp-manager-kafka-api-key,
    confluent_service_account.cmapp-producer,
    confluent_api_key.cmapp-producer-kafka-api-key,
    confluent_service_account.cmapp-consumer,
    confluent_api_key.cmapp-consumer-kafka-api-key,
  ]
  
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "./00_create_client.properties.sh ${confluent_api_key.cmapp-consumer-kafka-api-key.id} ${confluent_api_key.cmapp-consumer-kafka-api-key.secret} ${confluent_api_key.cmapp-producer-kafka-api-key.id} ${confluent_api_key.cmapp-producer-kafka-api-key.secret} ${resource.confluent_kafka_cluster.basic.bootstrap_endpoint} ${var.consumer_group} ${confluent_service_account.cmapp-manager.id} ${confluent_service_account.cmapp-manager.kind} ${confluent_service_account.cmapp-manager.api_version} ${confluent_service_account.cmapp-consumer.id} ${confluent_service_account.cmapp-consumer.kind} ${confluent_service_account.cmapp-consumer.api_version} ${confluent_service_account.cmapp-producer.id} ${confluent_service_account.cmapp-producer.kind} ${confluent_service_account.cmapp-producer.api_version} ${confluent_kafka_cluster.basic.id} ${confluent_kafka_cluster.basic.rest_endpoint} ${confluent_api_key.cmapp-manager-kafka-api-key.id} ${confluent_api_key.cmapp-manager-kafka-api-key.secret} ${var.environment_id} ${confluent_kafka_cluster.basic.id}"
  }
}