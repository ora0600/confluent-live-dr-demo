#!/bin/bash
source ./env-destination
echo "List all topics on secondary cluster: "
kafka-topics --bootstrap-server $bootstrap_secondary --list --command-config ../kafkatools_consumer_secondary.properties