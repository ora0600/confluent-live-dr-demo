# ---------------------------------------------------------------------
# We are using cmapp-manager: Has ClusterAdmin Role for Both Cluster
# -----------------------------------------------------------------------


# ---------------------------------------------------------------------
# Create Test Topic
# -----------------------------------------------------------------------
resource "confluent_kafka_topic" "test" {
  kafka_cluster {
    id = "${var.source_cluster_id}"
  }
  topic_name    = "test"
  rest_endpoint = "${var.source_endpoint}"
  credentials {
    key    = "${var.source_appmanager_key}"
    secret = "${var.source_appmanager_secret}"
  }

  depends_on = [
    confluent_kafka_cluster.dedicated 
  ]
}

# ---------------------------------------------------------------------
# Create cluster Link
# -----------------------------------------------------------------------
resource "confluent_cluster_link" "cmprod-passive-cmprod-cluster" {
  link_name = "cmprod_passive-cmprod_cluster_cluster_link"
  source_kafka_cluster {
    id                 = "${var.source_cluster_id}"
    bootstrap_endpoint = "${var.source_bootstrap}"
    credentials {
        key    = "${var.source_appmanager_key}"
        secret = "${var.source_appmanager_secret}"
    }
  }

  destination_kafka_cluster {
    id            = confluent_kafka_cluster.dedicated.id
    rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
    credentials {
      key    = confluent_api_key.cmapp-manager-kafka-api-key.id
      secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
    }
  }
  link_mode = "DESTINATION"
  connection_mode = "OUTBOUND"
  config = { "acl.sync.enable" = "true", 
             "acl.sync.ms" = "1000", 
             "acl.filters" = "{ \"aclFilters\": [ { \"resourceFilter\": { \"resourceType\": \"any\", \"patternType\": \"any\" }, \"accessFilter\": { \"operation\": \"any\", \"permissionType\": \"any\" } } ] }"
  }

}

# ---------------------------------------------------------------------
# Create Test Mirror-Topic
# -----------------------------------------------------------------------
resource "confluent_kafka_mirror_topic" "test" {
  source_kafka_topic {
    topic_name = confluent_kafka_topic.test.topic_name
  }
  cluster_link {
    link_name = confluent_cluster_link.cmprod-passive-cmprod-cluster.link_name
  }
  kafka_cluster {
    id            = confluent_kafka_cluster.dedicated.id
    rest_endpoint = confluent_kafka_cluster.dedicated.rest_endpoint
    credentials {
      key    = confluent_api_key.cmapp-manager-kafka-api-key.id
      secret = confluent_api_key.cmapp-manager-kafka-api-key.secret
    }
  }
}