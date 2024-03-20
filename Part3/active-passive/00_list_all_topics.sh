#!/bin/bash
source ./env-destination
echo "List all topics on secondary cluster: "
kafka-topics --bootstrap-server $destination_bootstrap --list --command-config ../kafkatools_consumer_secondary.properties

echo "List all mirror topics on secondary cluster: "
# kafka-mirrors --describe --bootstrap-server $destination_bootstrap --command-config ../kafkatools_consumer_secondary.properties --links passive-primary-secondary-cluster
confluent kafka mirror list --link passive-primary-secondary-cluster --cluster $cluster_destination_id --environment $destination_envid
