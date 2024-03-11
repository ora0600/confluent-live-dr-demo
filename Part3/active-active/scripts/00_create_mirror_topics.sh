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
echo "Press enter to continue with mirroring..."
read
echo "** Source Topics candidates for mirroring **"
while read p; do
  echo "Source Topic Mirroring candidate is: $p"
done <$sla_file
echo "** Do mirroring of Source Topics candidates:"
while read i; do
  if [[ -n "$i" ]]; then
    confluent kafka mirror create mirror-${i} --source-topic ${i} --cluster $cluster_destination_id --environment $destination_envid --link active-secondary-primary-cluster
    confluent kafka topic create ${i} --cluster $cluster_destination_id --environment $destination_envid
    confluent kafka mirror create mirror-${i} --source-topic ${i} --cluster $cluster_source_id --environment $source_envid --link active-primary-secondary-cluster
    confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic mirror-${i} --cluster $cluster_source_id --environment $source_envid
    confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic mirror-${i} --cluster $cluster_destination_id --environment $destination_envid
    confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic ${i} --cluster $cluster_source_id --environment $source_envid
    confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic ${i} --cluster $cluster_destination_id --environment $destination_envid
    #confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic cmcustomers --cluster $cluster_source_id --environment $source_envid
    #confluent kafka acl create --allow --service-account $consumer_said --operations read,describe --topic cmcustomers --cluster $cluster_destination_id --environment $destination_envid
    confluent kafka acl create --allow --service-account $consumer_said --operations read --consumer-group $groupid --cluster $cluster_source_id --environment $source_envid
    confluent kafka acl create --allow --service-account $consumer_said --operations read --consumer-group $groupid --cluster $cluster_destination_id --environment $destination_envid
    confluent kafka acl create --allow --service-account $producer_said --operations write --topic cmcustomers --cluster $cluster_source_id --environment $source_envid
    confluent kafka acl create --allow --service-account $producer_said --operations write --topic cmcustomers --cluster $cluster_destination_id --environment $destination_envid
  fi 
done <$sla_file
echo "Press enter to continue with start clients..."
read
echo "start clients on primary and secondary cluster"
kubectl create secret generic dr-kafka-client-consumer-config-secure-primary --from-file=../kafkatools_consumer_primary.properties --namespace confluent
kubectl create secret generic dr-kafka-client-consumer-config-secure-secondary --from-file=../kafkatools_consumer_secondary.properties --namespace confluent
kubectl create secret generic dr-kafka-client-producer-config-secure-primary --from-file=../kafkatools_producer_primary.properties --namespace confluent
kubectl create secret generic dr-kafka-client-producer-config-secure-secondary --from-file=../kafkatools_producer_secondary.properties --namespace confluent
kubectl get pods -n confluent
# Producers
kubectl apply -f ../dr-cloudproducercmcustomers-primary.yaml --namespace confluent
kubectl apply -f ../dr-cloudproducercmcustomers-secondary.yaml --namespace confluent
# kubectl delete -f ../dr-cloudproducercmcustomers-primary.yaml --namespace confluent
# kubectl delete -f ../dr-cloudproducercmcustomers-secondary.yaml --namespace confluent
# Deploy Consumer
kubectl apply -f ../dr-cloudconsumercmcustomers-primary.yaml --namespace confluent
kubectl apply -f ../dr-cloudconsumercmcustomers-secondary.yaml --namespace confluent
# kubectl delete -f ../dr-cloudconsumercmcustomers-primary.yaml --namespace confluent
# kubectl delete -f ../dr-cloudconsumercmcustomers-secondary.yaml --namespace confluent
kubectl get pods -n confluent

echo "clients are running, and cmcustomer mirroring active active is setup."
