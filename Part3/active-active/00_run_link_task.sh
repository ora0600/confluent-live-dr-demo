#!/bin/bash
source ./env-destination

# see Docu: https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/cluster-links-cc.html#view-a-cluster-link-task-status
echo "Show Link Task of cluster bidirectional in primary cluster: "
confluent kafka link task list bidirectional --cluster $cluster_source_id --environment $source_envid
echo ""
echo "Show Link Task of cluster link bidirectional in secondary cluster: "
confluent kafka link task list bidirectional --cluster $cluster_destination_id --environment $destination_envid
