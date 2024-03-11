#!/bin/bash
source ./env-destination

# see Docu: https://docs.confluent.io/cloud/current/monitoring/monitor-lag.html
echo "Run Offset Monitoring for Primary Cluster  Group $groupid : "
kafka-consumer-groups --bootstrap-server $source_bootstrap --describe --group $groupid --offsets --command-config ../kafkatools_prod_consumer_offset_primary.properties 
echo "Run Offset Monitoring for Secondary Cluster  Group $groupid : "
kafka-consumer-groups --bootstrap-server $destination_bootstrap --describe --group $groupid --offsets --command-config ../kafkatools_prod_consumer_offset_secondary.properties 