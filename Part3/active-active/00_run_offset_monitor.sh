#!/bin/bash
source ./env-destination

# see Docu: https://docs.confluent.io/cloud/current/monitoring/monitor-lag.html
echo "Run Offset Monitoring for Secondary Cluster  Group $groupid : "
kafka-consumer-groups --bootstrap-server $bootstrap_secondary --describe --group $groupid --offsets --command-config ../kafkatools_prod_consumer_offset_secondary.properties 