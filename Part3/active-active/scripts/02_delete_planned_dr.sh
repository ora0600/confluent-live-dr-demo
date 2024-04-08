#!/bin/bash

source ./env-destination

aEnv=$source_envid
bEnv=$destination_envid
aID=$cluster_source_id
bID=$cluster_destination_id
aBootstrap=$source_bootstrap
bBootstrap=$destination_bootstrap
aApiKey=$appmanagerkey_primary
aApiSecret=$appmanagersecret_primary
bApiKey=$appmanagerkey_secondary
bApiSecret=$appmanagersecret_secondary
saID=$appmanager_said
topicname=`cat scripts/sla_planneddr_topics.txt`

# Delete planned DR
echo "Delete Planned DR resources"
echo "Delete mirror topic on secondary cluster"
confluent kafka topic delete $topicname  --cluster $bID --environment $bEnv --force
echo "delete Links"
confluent kafka link delete bidirectional-link --cluster $bID --environment $bEnv --force
confluent kafka link delete bidirectional-link --cluster $aID --environment $aEnv --force
echo "Planned DR resources are deleted"