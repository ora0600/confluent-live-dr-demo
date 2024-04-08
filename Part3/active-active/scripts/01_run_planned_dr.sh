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

sla_file="./scripts/sla_planneddr_topics.txt"
topicname=`cat scripts/sla_planneddr_topics.txt`

# Login to Confluent
confluent login

# Create topic on primary
echo "************* Start Primary Setup *************"
echo "create topic $topicname on primary cluster"
confluent kafka topic create $topicname --partitions 1 --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations read,describe-configs --topic $topicname --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations describe,alter --cluster-scope --cluster $aID --environment $aEnv
confluent kafka acl create --allow --service-account $saID --operations read,describe-configs --topic $topicname --cluster $bID --environment $bEnv
confluent kafka acl create --allow --service-account $saID --operations describe,alter --cluster-scope --cluster $bID --environment $bEnv
echo "************* Create CLs *************"
echo "** bidirectional link on both sides **"
echo "link.mode=BIDIRECTIONAL" > bidirectional-link.config
echo "create bidirectional-link on secondary cluster"
confluent kafka link create bidirectional-link \
--cluster $bID \
--environment $bEnv \
--source-bootstrap-server $bBootstrap \
--local-api-key $bApiKey \
--local-api-secret $bApiSecret \
--remote-cluster $aID \
--remote-api-key $aApiKey \
--remote-api-secret $aApiSecret \
--remote-bootstrap-server $aBootstrap \
--config bidirectional-link.config
echo "create bidirectional-link on primary cluster"
confluent kafka link create bidirectional-link \
--cluster $aID \
--environment $aEnv \
--source-bootstrap-server $aBootstrap \
--local-api-key $aApiKey \
--local-api-secret $aApiSecret \
--remote-cluster $bID \
--remote-api-key $bApiKey \
--remote-api-secret $bApiSecret \
--remote-bootstrap-server $bBootstrap \
--config bidirectional-link.config
echo "************* Start Mirroring *************"
echo "*****         Source Topics          ******"
for i in `confluent kafka topic list --environment $aEnv --cluster $aID -o yaml | awk '/- name:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
do
   echo "Source Topic: ${i}"
done
echo "Press enter to continue with mirroring..."
read
echo "** Source Topics candidates for mirroring **"
while read p; do
  echo "Source Topic Mirroring candidate is: ==>  $p"
done <$sla_file
echo "** Do mirroring of Source Topics candidates:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror create ${i} --link bidirectional-link --cluster $bID --environment $bEnv
  fi 
done <$sla_file
echo "Mirroring is configured, check on secondary cluster if data is flow into mirrored mirror-cmtopic..."
echo "Press enter to continue, describe mirror topic on secondary cluster..."
read
confluent kafka mirror describe $topicname  --link bidirectional-link --cluster $bID --environment $bEnv
echo "Press enter to Start clients..."
read
# Start clients on primary cluster produce and consume from cmtopic 
echo " Start clients on primary cluster produce and consume from cmtopic"
# Deploy Secrets
cp ../kafkatools_consumer_primary.properties  ../kafkatools_consumer.properties 
cp ../kafkatools_producer_primary.properties ../kafkatools_producer.properties
cp ../kafkatools_consumer_secondary.properties  ../kafkatools_consumer-mirror.properties 
kubectl create secret generic prod-cloudconsumercmtopic-config-secure --from-file=../kafkatools_consumer.properties --namespace confluent
kubectl create secret generic prod-cloudproducercmtopic-config-secure --from-file=../kafkatools_producer.properties --namespace confluent
kubectl create secret generic prod-cloudconsumercmtopic-mirror-config-secure --from-file=../kafkatools_consumer-mirror.properties --namespace confluent
# Deploy Producer on primary
kubectl apply -f ../prod-cloudproducercmtopic.yaml --namespace confluent
# Deploy Consumer on primary
kubectl apply -f ../prod-cloudconsumercmtopic.yaml --namespace confluent
# Deploy Mirror Consumer on secondary
kubectl apply -f ../prod-cloudconsumercmtopic-mirror.yaml --namespace confluent
#
echo "Clients are now running, check in Confluent UI on primary cluster is data is produced and consumed on topic cmtopic."
echo "Press enter to continue with failover (reverse and start) on secondary cluster..."
read
# Now, do failover:
echo "Do a failover:"
echo "confluent kafka mirror reverse-and-start an secondary:"
while read i; do
  if [[ -n "$i" ]]; then
    echo "Mirror Topic describe on secondary"
    confluent kafka mirror describe ${i}  --link bidirectional-link --cluster $bID --environment $bEnv
    echo "Start reverse-and-start on secondary"
    confluent kafka mirror reverse-and-start ${i}  --link bidirectional-link --cluster $bID --environment $bEnv
    echo "Check if mirror topic stopped on secondary"
    confluent kafka mirror describe  ${i}  --link bidirectional-link --cluster $bID --environment $bEnv
    echo "Check if mirror topic active on primary"
    confluent kafka mirror describe  ${i}  --link bidirectional-link --cluster $aID --environment $aEnv
    echo "Mirrored topic became prod topic (secondary cluster) and this will be mirrored (Primary) of Topic ${i}"
  fi 
done <$sla_file
echo "Check in Cloud UI under cluster link bidirectional-woprefix if mirroring is working (now in primary)."
echo "Press enter to continue with clients switchover..."
read
echo "Stop Clients and restart:"
# Copy file for secondary
cp ../kafkatools_consumer_secondary.properties  ../kafkatools_consumer.properties 
cp ../kafkatools_producer_secondary.properties ../kafkatools_producer.properties
cp ../kafkatools_consumer_primary.properties  ../kafkatools_consumer-mirror.properties 
# Rewrite secrets
kubectl create secret generic prod-cloudconsumercmtopic-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic prod-cloudproducercmtopic-config-secure --save-config --dry-run=client --from-file=../kafkatools_producer.properties -o yaml | kubectl apply -f -
kubectl create secret generic prod-cloudconsumercmtopic-mirror-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer-mirror.properties -o yaml | kubectl apply -f -
# Show pods
kubectl get pods -n confluent
echo "Check in Cloud UI under cluster link bidirectional-woprefix if mirroring (primary cluster), producing and consuming (secondary cluster) is working."
echo "Press enter to continue with failback (reverse-and-pause and resume)..."
read
echo "Do a failback:"
echo "confluent kafka mirror reverse-and-pause and then resume:"
while read i; do
  if [[ -n "$i" ]]; then
    echo "reverse-and-pause on primary"
    confluent kafka mirror reverse-and-pause ${i} --link bidirectional-link --cluster $aID --environment $aEnv
    echo "Do resume on secondary cluster"
    confluent kafka mirror resume  ${i}  --link bidirectional-link --cluster $bID --environment $bEnv
    echo "describe mirror on primary of stopped"
    confluent kafka mirror describe ${i}  --link bidirectional-link --cluster $aID --environment $aEnv
    echo "describe mirror on secondary if active"
    confluent kafka mirror describe ${i}  --link bidirectional-link --cluster $bID --environment $bEnv
    echo "mirror topic from primary is now switched to secondary cluster, and is back in original status"
  fi 
done <$sla_file
echo "Check in Cloud UI under cluster link bidirectional-woprefix if mirroring is working (now in secondary)."
echo "Press enter to continue with clients switchover..."
read
echo "Stop Clients and restart:"
# Copy file for secondary
cp ../kafkatools_consumer_primary.properties  ../kafkatools_consumer.properties 
cp ../kafkatools_producer_primary.properties ../kafkatools_producer.properties
cp ../kafkatools_consumer_secondary.properties  ../kafkatools_consumer-mirror.properties
# Rewrite secrets
kubectl create secret generic prod-cloudconsumercmtopic-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic prod-cloudproducercmtopic-config-secure --save-config --dry-run=client --from-file=../kafkatools_producer.properties -o yaml | kubectl apply -f -
kubectl create secret generic prod-cloudconsumercmtopic-mirror-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer-mirror.properties -o yaml | kubectl apply -f -
# Show pods
kubectl get pods -n confluent
echo "Check in Cloud UI under cluster link bidirectional-woprefix if mirroring (secondary cluster), producing and consuming (primary cluster) is working."
echo "Show Link Task of cluster bidirectional-woprefix in primary cluster: "
confluent kafka link task list bidirectional-woprefix --cluster $cluster_source_id --environment $source_envid
echo ""
echo "Show Link Task of cluster link bidirectional-woprefix in secondary cluster: "
confluent kafka link task list bidirectional-woprefix --cluster $cluster_destination_id --environment $destination_envid
echo "Planned DR exercise is finished, back in ready state"
