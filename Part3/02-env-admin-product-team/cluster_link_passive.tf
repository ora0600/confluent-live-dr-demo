# ---------------------------------------------------------------------
# We are using cmapp-drmanager: Has ClusterAdmin Role for Both Cluster
# -----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Create Test Topic in primary cluster
# -----------------------------------------------------------------------
resource "confluent_kafka_topic" "test" {
  kafka_cluster {
    id = confluent_kafka_cluster.primary.id
  }
  topic_name    = "test"
  rest_endpoint = confluent_kafka_cluster.primary.rest_endpoint
  credentials {
    key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
    secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
  }

  depends_on = [
    confluent_kafka_cluster.primary
  ]
}


# ---------------------------------------------------------------------
# Create cluster Link one direction - secondary to primary (passive)
# -----------------------------------------------------------------------
resource "confluent_cluster_link" "passive-primary-secondary-cluster" {
  link_name = "passive-primary-secondary-cluster"
  source_kafka_cluster {
    id                 = confluent_kafka_cluster.primary.id
    bootstrap_endpoint = confluent_kafka_cluster.primary.bootstrap_endpoint
    credentials {
        key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
        secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
    }
  }

  destination_kafka_cluster {
    id            = confluent_kafka_cluster.secondary.id
    rest_endpoint = confluent_kafka_cluster.secondary.rest_endpoint
    credentials {
      key    = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id
      secret = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret
    }
  }
  link_mode = "DESTINATION"
  connection_mode = "OUTBOUND"
  config = { "acl.sync.enable" = "true", 
             "acl.sync.ms" = "1000", 
             "acl.filters" = "{ \"aclFilters\": [ { \"resourceFilter\": { \"resourceType\": \"any\", \"patternType\": \"any\" }, \"accessFilter\": { \"operation\": \"any\", \"permissionType\": \"any\" } } ] }",
             "topic.config.sync.ms" = "1000",
             "consumer.offset.sync.enable" = "true",
             "consumer.offset.group.filters" = "{\"groupFilters\": [{\"name\": \"*\",\"patternType\": \"LITERAL\",\"filterType\": \"INCLUDE\"}]}",
             "consumer.offset.sync.ms" = "1000"
  }
  depends_on = [
    confluent_kafka_cluster.primary,
    confluent_kafka_cluster.secondary,
    confluent_api_key.cmapp-drmanager-primary-kafka-api-key,
    confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key,
  ]
}

# ---------------------------------------------------------------------
# Create Test Mirror-Topic
# -----------------------------------------------------------------------
resource "confluent_kafka_mirror_topic" "test" {
  source_kafka_topic {
    topic_name = confluent_kafka_topic.test.topic_name
  }
  cluster_link {
    link_name = confluent_cluster_link.passive-primary-secondary-cluster.link_name
  }
  kafka_cluster {
    id            = confluent_kafka_cluster.secondary.id
    rest_endpoint = confluent_kafka_cluster.secondary.rest_endpoint
    credentials {
      key    = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id
      secret = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret
    }
  }
}
