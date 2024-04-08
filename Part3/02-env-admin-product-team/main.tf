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
# Primary Cluster
# ---------------------------------------------------
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
# Create dedicated Cluster in Environment
# ---------------------------------------------------
resource "confluent_kafka_cluster" "primary" {
  display_name = var.cluster_name
  availability = "SINGLE_ZONE"
  cloud        = var.csp
  region       = var.region
  
  dynamic "basic" {
    for_each = [for value in [var.cluster_type] : value if value == "BASIC"]
    content {
    }
  }
  dynamic "dedicated" {
    for_each = [for value in [var.cluster_type] : value if value == "DEDICATED"]
    content {
      cku = 1
    }
  }
  environment {
    id = data.confluent_environment.cmprod.id
  }
}

# ---------------------------------------------------
# Create Service Accounts: cmapp-drmanager
# 'app-manager' service account is required in this configuration to create 'cmorders' topic and grant ACLs
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-drmanager" {
  display_name = "cmapp-drmanager"
  description  = "Service account to manage Kafka cluster"
}

resource "confluent_role_binding" "cmapp-drmanager-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.cmapp-drmanager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.primary.rbac_crn
}

resource "confluent_api_key" "cmapp-drmanager-primary-kafka-api-key" {
  display_name = "cmapp-drmanager-primary-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-drmanager' service account"
  owner {
    id          = confluent_service_account.cmapp-drmanager.id
    api_version = confluent_service_account.cmapp-drmanager.api_version
    kind        = confluent_service_account.cmapp-drmanager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.primary.id
    api_version = confluent_kafka_cluster.primary.api_version
    kind        = confluent_kafka_cluster.primary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }

  depends_on = [
    confluent_role_binding.cmapp-drmanager-kafka-cluster-admin
  ]
}

# ---------------------------------------------------
# Create Topic cmorders as 'cmapp-drmanager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmorders" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name    = "cmorders"
  partitions_count   = 1
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

# ---------------------------------------------------
# Create Topic cmcustomers as 'cmapp-drmanager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name    = "cmcustomers"
  partitions_count   = 1
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

# ---------------------------------------------------
# Create Topic cmproducts as 'cmapp-drmanager' service account
# ---------------------------------------------------
resource "confluent_kafka_topic" "cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name    = "cmproducts"
  partitions_count   = 1
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

# ---------------------------------------------------
# Create Service Accounts: cmapp-drconsumer with API KEY
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-drconsumer" {
  display_name = "cmapp-drconsumer"
  description  = "Service account to consume from 'cmorders' topic of Kafka cluster"
}

resource "confluent_api_key" "cmapp-drconsumer-primary-kafka-api-key" {
  display_name = "cmapp-drconsumer-primary-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-consumer' service account"
  owner {
    id          = confluent_service_account.cmapp-drconsumer.id
    api_version = confluent_service_account.cmapp-drconsumer.api_version
    kind        = confluent_service_account.cmapp-drconsumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.primary.id
    api_version = confluent_kafka_cluster.primary.api_version
    kind        = confluent_kafka_cluster.primary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }
}

# ---------------------------------------------------
# Create Service Accounts: cmapp-drproducer with Keys
# ---------------------------------------------------
resource "confluent_service_account" "cmapp-drproducer" {
  display_name = "cmapp-drproducer"
  description  = "Service account to produce to 'cmorders' topic of Kafka cluster"
}

resource "confluent_api_key" "cmapp-drproducer-primary-kafka-api-key" {
  display_name = "cmapp-drproducer-primary-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-producer' service account"
  owner {
    id          = confluent_service_account.cmapp-drproducer.id
    api_version = confluent_service_account.cmapp-drproducer.api_version
    kind        = confluent_service_account.cmapp-drproducer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.primary.id
    api_version = confluent_kafka_cluster.primary.api_version
    kind        = confluent_kafka_cluster.primary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }
}

# ---------------------------------------------------
# Create ACL for Service Accounts: cmapp-drproducer
# ---------------------------------------------------
resource "confluent_kafka_acl" "cmapp-drproducer-write-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmorders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drproducer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-drproducer-write-on-cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmcustomers.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drproducer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-drproducer-write-on-cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmproducts.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drproducer.id}"
  host          = "*"
  operation     = "WRITE"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}


# ---------------------------------------------------
# Create ACL for Service Accounts: cmapp-drconsumer
# ---------------------------------------------------
resource "confluent_kafka_acl" "cmapp-drconsumer-read-on-topic" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmorders.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drconsumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-drconsumer-read-on-cmcustomers" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmcustomers.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drconsumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-drconsumer-read-on-cmproducts" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "TOPIC"
  resource_name = confluent_kafka_topic.cmproducts.topic_name
  pattern_type  = "LITERAL"
  principal     = "User:${confluent_service_account.cmapp-drconsumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}

resource "confluent_kafka_acl" "cmapp-drconsumer-read-on-group" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  resource_type = "GROUP"
  resource_name = var.consumer_group
  pattern_type  = "PREFIXED"
  principal     = "User:${confluent_service_account.cmapp-drconsumer.id}"
  host          = "*"
  operation     = "READ"
  permission    = "ALLOW"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }
}


# ---------------------------------------------------
# Secondary Cluster
# ---------------------------------------------------
# ---------------------------------------------------
# Create dedicated DR Cluster in Environment
# ---------------------------------------------------
resource "confluent_kafka_cluster" "secondary" {
  display_name = var.cluster_name_dr
  availability = "SINGLE_ZONE"
  cloud        = var.csp_dr
  region       = var.region_dr
  
  dynamic "basic" {
    for_each = [for value in [var.cluster_type] : value if value == "BASIC"]
    content {
    }
  }
  dynamic "dedicated" {
    for_each = [for value in [var.cluster_type] : value if value == "DEDICATED"]
    content {
      cku = 1
    }
  }
  environment {
    id = data.confluent_environment.cmprod.id
  }
}

# ---------------------------------------------------
# Align Service Accounts: cmapp-drmanager resource
# ---------------------------------------------------
resource "confluent_role_binding" "cmapp-drmanager-secondary-kafka-cluster-admin" {
  principal   = "User:${confluent_service_account.cmapp-drmanager.id}"
  role_name   = "CloudClusterAdmin"
  crn_pattern = confluent_kafka_cluster.secondary.rbac_crn
}

resource "confluent_api_key" "cmapp-drmanager-secondary-kafka-cluster-api-key" {
  display_name = "cmapp-drmanager-secondary-kafka-cluster-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-drmanager' service account"
  owner {
    id          = confluent_service_account.cmapp-drmanager.id
    api_version = confluent_service_account.cmapp-drmanager.api_version
    kind        = confluent_service_account.cmapp-drmanager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.secondary.id
    api_version = confluent_kafka_cluster.secondary.api_version
    kind        = confluent_kafka_cluster.secondary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }

  depends_on = [
    confluent_role_binding.cmapp-drmanager-secondary-kafka-cluster-admin
  ]
}

# ---------------------------------------------------
#  Service Accounts: cmapp-drconsumer with API KEY
# ---------------------------------------------------
resource "confluent_api_key" "cmapp-drconsumer-secondary-kafka-api-key" {
  display_name = "cmapp-drconsumer-secondary-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-drconsumer' service account"
  owner {
    id          = confluent_service_account.cmapp-drconsumer.id
    api_version = confluent_service_account.cmapp-drconsumer.api_version
    kind        = confluent_service_account.cmapp-drconsumer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.secondary.id
    api_version = confluent_kafka_cluster.secondary.api_version
    kind        = confluent_kafka_cluster.secondary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }
}

# ---------------------------------------------------
# Service Accounts: cmapp-drproducer with Keys
# ---------------------------------------------------
resource "confluent_api_key" "cmapp-drproducer-secondary-kafka-api-key" {
  display_name = "cmapp-drproducer-secondary-kafka-api-key"
  description  = "Kafka API Key that is owned by 'cmapp-producer' service account"
  owner {
    id          = confluent_service_account.cmapp-drproducer.id
    api_version = confluent_service_account.cmapp-drproducer.api_version
    kind        = confluent_service_account.cmapp-drproducer.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.secondary.id
    api_version = confluent_kafka_cluster.secondary.api_version
    kind        = confluent_kafka_cluster.secondary.kind

    environment {
      id = data.confluent_environment.cmprod.id
    }
  }
}

# ---------------------------------------------------------------
# Run Local Script for create properties files and start clients
# ----------------------------------------------------------------
resource "null_resource" "properties" {
  depends_on = [
    data.confluent_environment.cmprod,
    confluent_kafka_cluster.primary,
    confluent_kafka_cluster.secondary,
    confluent_service_account.cmapp-drmanager,
    confluent_api_key.cmapp-drmanager-primary-kafka-api-key,
    confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key,
    confluent_service_account.cmapp-drproducer,
    confluent_api_key.cmapp-drproducer-primary-kafka-api-key,
    confluent_api_key.cmapp-drproducer-secondary-kafka-api-key,
    confluent_service_account.cmapp-drconsumer,
    confluent_api_key.cmapp-drconsumer-primary-kafka-api-key,
    confluent_api_key.cmapp-drconsumer-secondary-kafka-api-key
  ]
  triggers = {
    always_run = "${timestamp()}"
  }
  provisioner "local-exec" {
    command = "./00_create_client.properties.sh ${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.id} ${confluent_api_key.cmapp-drconsumer-primary-kafka-api-key.secret} ${confluent_api_key.cmapp-drconsumer-secondary-kafka-api-key.id} ${confluent_api_key.cmapp-drconsumer-secondary-kafka-api-key.secret} ${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.id} ${confluent_api_key.cmapp-drproducer-primary-kafka-api-key.secret} ${confluent_api_key.cmapp-drproducer-secondary-kafka-api-key.id} ${confluent_api_key.cmapp-drproducer-secondary-kafka-api-key.secret} ${confluent_kafka_cluster.primary.bootstrap_endpoint} ${confluent_kafka_cluster.secondary.bootstrap_endpoint} ${var.consumer_group} ${confluent_kafka_cluster.primary.id} ${confluent_kafka_cluster.primary.rest_endpoint} ${confluent_kafka_cluster.secondary.id} ${confluent_kafka_cluster.secondary.rest_endpoint} ${confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id} ${confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret} ${confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id} ${confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret} ${var.environment_id} ${confluent_service_account.cmapp-drconsumer.id} ${confluent_service_account.cmapp-drproducer.id} ${confluent_service_account.cmapp-drmanager.id}"
    }
}