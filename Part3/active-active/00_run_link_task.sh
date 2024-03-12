#!/bin/bash
source ./env-destination

# see Docu: https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/cluster-links-cc.html#view-a-cluster-link-task-status
echo "Show Link Task of cluster link active-primary-secondary-cluster in primary cluster: "
confluent kafka link task list active-primary-secondary-cluster --cluster $cluster_source_id --environment $source_envid
echo ""
echo "Show Link Task of cluster link active-secondary-primary-cluster in secondary cluster: "
confluent kafka link task list active-secondary-primary-cluster --cluster $cluster_destination_id --environment $destination_envid
