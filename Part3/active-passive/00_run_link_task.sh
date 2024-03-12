#!/bin/bash
source ./env-destination

# see Docu: https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/cluster-links-cc.html#view-a-cluster-link-task-status
echo "Show Link Task of cluster link passive-primary-secondary-cluster in secondary cluster: "
confluent kafka link task list passive-primary-secondary-cluster --cluster $cluster_destination_id --environment $destination_envid
