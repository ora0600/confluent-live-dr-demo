#!/bin/bash
source ./env-destination
echo "List all topics on secondary cluster: "
kafka-topics --bootstrap-server $destination_bootstrap --list --command-config ../kafkatools_consumer_secondary.properties