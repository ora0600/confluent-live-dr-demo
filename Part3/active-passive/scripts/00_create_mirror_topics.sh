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
echo "** Source Topics candidates for mirroring **"
while read p; do
  echo "Source Topic Mirroring candidate is: $p"
done <$sla_file
echo "** Do mirroring of Source Topics candidates:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror create ${i} --cluster $cluster_destination_id --environment $destination_envid --link cmprod_passive-cmprod_cluster_cluster_link
    echo "Topic ${i} mirrored"
  fi 
done <$sla_file

echo "Mirroring is finished"
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

# Now, do failover:
echo "Do a failover:"
echo "Stop mirroring first:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror failover ${i}  --link cmprod_passive-cmprod_cluster_cluster_link --cluster $cluster_destination_id --environment $destination_envid
    echo "Mirroring of Topic ${i} stopped, Topic writable"
  fi 
done <$sla_file
echo "Stop Clients and restart:"
kubectl get pods -n confluent
kubectl create secret generic kafka-client-consumer-config-secure --save-config --dry-run=client --from-file=../../Part1/kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic kafka-client-producer-config-secure --save-config --dry-run=client --from-file=../../Part1/kafkatools_producer.properties -o yaml | kubectl apply -f -
# Producers
kubectl delete -f ../../Part1/cloudproducercmcustomers.yaml --namespace confluent 2> /dev/null
kubectl delete -f ../../Part1/cloudproducercmproducts.yaml --namespace confluent 2> /dev/null
# Deploy Consumer
kubectl delete  -f ../../Part1/cloudconsumercmcustomers.yaml --namespace confluent 2> /dev/null
kubectl delete  -f ../../Part1/cloudconsumercmproducts.yaml --namespace confluent 2> /dev/null
kubectl get pods -n confluent

