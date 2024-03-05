#!/bin/bash

export bootstrap=$(echo -e "$(terraform output -raw cc_kafka_cluster_bootsrap)")

echo "List all topics: "
kafka-topics --bootstrap-server $bootstrap --list --command-config ../kafkatools_consumer.properties