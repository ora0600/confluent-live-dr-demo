# ---------------------------------------------------------------------
# We are using cmapp-drmanager: Has ClusterAdmin Role for Both Cluster
# -----------------------------------------------------------------------

# ---------------------------------------------------------------------
# Create cluster Link bi-directional primary - secondary (active)
# -----------------------------------------------------------------------
resource "confluent_cluster_link" "active-primary-secondary-cluster" {
  link_name = "active-primary-secondary-cluster"
  link_mode = "BIDIRECTIONAL"
  local_kafka_cluster {
    id                 = confluent_kafka_cluster.primary.id
    rest_endpoint      = confluent_kafka_cluster.primary.rest_endpoint
    credentials {
        key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
        secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
    }
  }
  remote_kafka_cluster {
    id            = confluent_kafka_cluster.secondary.id
    bootstrap_endpoint = confluent_kafka_cluster.secondary.bootstrap_endpoint
    credentials {
      key    = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id
      secret = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret
    }
  }
  config = { "acl.sync.enable" = "false", 
             "acl.sync.ms" = "1000", 
             "acl.filters" = "{ \"aclFilters\": [ { \"resourceFilter\": { \"resourceType\": \"any\", \"patternType\": \"any\" }, \"accessFilter\": { \"operation\": \"any\", \"permissionType\": \"any\" } } ] }",
             "topic.config.sync.ms" = "1000",
             "consumer.offset.sync.enable" = "true",
             "consumer.offset.group.filters" = "{\"groupFilters\": [{\"name\": \"*\",\"patternType\": \"LITERAL\",\"filterType\": \"INCLUDE\"}]}",
             "consumer.offset.sync.ms" = "1000",
             "cluster.link.prefix" ="mirror-"
  }
  depends_on = [
    confluent_kafka_cluster.primary,
    confluent_kafka_cluster.secondary,
    confluent_api_key.cmapp-drmanager-primary-kafka-api-key,
    confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key,
  ]

}

# ---------------------------------------------------------------------
# Create cluster Link bi-directional secondary - primary  (active)
# -----------------------------------------------------------------------
resource "confluent_cluster_link" "active-secondary-primary-cluster" {
  link_name = "active-secondary-primary-cluster"
  link_mode = "BIDIRECTIONAL"
  local_kafka_cluster {
    id                 = confluent_kafka_cluster.secondary.id
    rest_endpoint      = confluent_kafka_cluster.secondary.rest_endpoint
    credentials {
        key    = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.id
        secret = confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key.secret
    }
  }
  remote_kafka_cluster {
    id            = confluent_kafka_cluster.primary.id
    bootstrap_endpoint = confluent_kafka_cluster.primary.bootstrap_endpoint
    credentials {
      key    = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.id
      secret = confluent_api_key.cmapp-drmanager-primary-kafka-api-key.secret
    }
  }
  config = { "acl.sync.enable" = "false", 
             "acl.sync.ms" = "1000", 
             "acl.filters" = "{ \"aclFilters\": [ { \"resourceFilter\": { \"resourceType\": \"any\", \"patternType\": \"any\" }, \"accessFilter\": { \"operation\": \"any\", \"permissionType\": \"any\" } } ] }",
             "topic.config.sync.ms" = "1000",
             "consumer.offset.sync.enable" = "true",
             "consumer.offset.group.filters" = "{\"groupFilters\": [{\"name\": \"*\",\"patternType\": \"LITERAL\",\"filterType\": \"INCLUDE\"}]}",
             "consumer.offset.sync.ms" = "1000",
             "cluster.link.prefix" ="mirror-"
  }
  depends_on = [
    confluent_kafka_cluster.primary,
    confluent_kafka_cluster.secondary,
    confluent_api_key.cmapp-drmanager-primary-kafka-api-key,
    confluent_api_key.cmapp-drmanager-secondary-kafka-cluster-api-key,
  ]

}
