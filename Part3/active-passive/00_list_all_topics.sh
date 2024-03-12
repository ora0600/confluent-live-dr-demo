#!/bin/bash
source ./env-destination
echo "List all topics on secondary cluster: "
kafka-topics --bootstrap-server $destination_bootstrap --list --command-config ../kafkatools_consumer_secondary.properties

echo "List all mirror topics on secondary cluster: "
kafka-mirrors --describe --bootstrap-server $destination_bootstrap --command-config ../kafkatools_consumer_secondary.properties --link passive-primary-secondary-cluster
