#!/bin/bash
source ./env-destination
echo "List all topics on secondary cluster: "
kafka-topics --list --bootstrap-server $destination_bootstrap --command-config ../kafkatools_consumer_secondary.properties
echo "List all topics on primary cluster: "
kafka-topics  --list --bootstrap-server $source_bootstrap --command-config ../kafkatools_consumer_primary.properties

echo "List all mirror topics on secondary cluster: "
kafka-mirrors --describe --bootstrap-server $destination_bootstrap --command-config ../kafkatools_consumer_secondary.properties --link active-secondary-primary-cluster
echo "List all mirror topics on primary cluster: "
kafka-mirrors --describe --bootstrap-server $source_bootstrap --command-config ../kafkatools_consumer_primary.properties --link active-primary-secondary-cluster
