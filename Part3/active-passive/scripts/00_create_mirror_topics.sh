#!/bin/bash

source ./env-destination

sla_file="./scripts/sla_gold_topics.txt"


# Login to Confluent
confluent login

echo "************* Start Mirroring *************"
echo "*****         Source Topics          ******"
for i in `confluent kafka topic list --environment $source_envid --cluster $cluster_source_id -o yaml | awk '/- name:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
do
   echo "Source Topic: ${i}"
done
echo "Press enter to continue..."
read
echo "** Source Topics candidates for mirroring **"
while read p; do
  echo "Source Topic Mirroring candidate is: $p"
done <$sla_file
echo "Press enter to continue with Mirroring..."
read
echo "** Do mirroring of Source Topics candidates:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror create ${i} --link passive-primary-secondary-cluster --cluster $cluster_destination_id --environment $destination_envid 
    echo "Topic ${i} mirrored"
  fi 
done <$sla_file
echo "Mirroring is finished"
echo "Check in Cloud UI under cluster link passive-primary-secondary-cluster. Press enter to continue with check ACL sync..."
read
# Check if ACL is existng in destination cluster
for i in `confluent kafka acl list --cluster $cluster_destination_id --environment $destination_envid -o yaml | awk '/principal: User:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
do
  echo "Service Account ACL for   ${i} => check it:"
  #confluent iam service-account list -o yaml | grep ${i}
  if [[ $(confluent iam  service-account list -o yaml| grep ${i}) ]]; then
    echo "Service account ${i} still exists, ACL is good"
    confluent kafka acl list --cluster $cluster_destination_id --environment $destination_envid -o human --service-account  ${i}
    echo "Key is also created in destination cluster $cluster_destination_id:"
    confluent api-key list --resource $cluster_destination_id --environment $destination_envid --service-account ${i}
  fi
done
echo "Press enter to continue with failover..."
read
# Now, do failover:
echo "Do a failover:"
echo "Stop mirroring first:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror failover ${i}  --link passive-primary-secondary-cluster --cluster $cluster_destination_id --environment $destination_envid
    echo "Mirroring of Topic ${i} stopped, Topic writable"
  fi 
done <$sla_file
echo "Check in Cloud UI under cluster link passive-primary-secondary-cluster. Press enter to continue with clients switchover..."
read
echo "Stop Clients and restart:"
kubectl get pods -n confluent
# Copy file for secondary
cp ../kafkatools_consumer_secondary.properties  ../kafkatools_consumer.properties 
cp ../kafkatools_producer_secondary.properties ../kafkatools_producer.properties
# Rewrite secrets
kubectl create secret generic dr-kafka-client-consumer-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic dr-kafka-client-producer-config-secure --save-config --dry-run=client --from-file=../kafkatools_producer.properties -o yaml | kubectl apply -f -
# Producers delete
kubectl delete -f ../prod-cloudproducercmcustomers.yaml --namespace confluent 2> /dev/null
kubectl delete -f ../prod-cloudproducercmproducts.yaml --namespace confluent 2> /dev/null
# kubectl delete -f ../prod-cloudproducercmorders.yaml --namespace confluent 2> /dev/null
# Deploy Consumer delete
kubectl delete  -f ../prod-cloudconsumercmcustomers.yaml --namespace confluent 2> /dev/null
kubectl delete  -f ../prod-cloudconsumercmproducts.yaml --namespace confluent 2> /dev/null
# kubectl delete  -f ../prod-cloudconsumercmorders.yaml --namespace confluent 2> /dev/null
kubectl get pods -n confluent

echo "Failover is done, and client run now on SLA relatic topics on Seconday Cluster"

