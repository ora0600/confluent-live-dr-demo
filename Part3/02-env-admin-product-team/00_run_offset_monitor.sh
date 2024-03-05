#!/bin/bash

export bootstrap=$(echo -e "$(terraform output -raw cc_kafka_cluster_bootsrap)")
export groupid=$(echo -e "$(terraform output -raw consumer_group)")

# see Docu: https://docs.confluent.io/cloud/current/monitoring/monitor-lag.html
echo "Run Offset Monitoring for Productcluster Group $groupid : "
kafka-consumer-groups --bootstrap-server $bootstrap --describe --group $groupid --offsets --command-config ../kafkatools_prod_consumer_offset.properties 