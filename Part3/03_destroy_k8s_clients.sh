#!/bin/bash

echo "*************************** PODS *******************************"
kubectl get pods -n confluent
kubectl delete  -f prod-cloudconsumercmorders.yaml  --namespace confluevnt
kubectl delete  -f dr-cloudproducercmcustomers-primary.yaml  --namespace confluent
kubectl delete  -f dr-cloudproducercmcustomers-secondary.yaml  --namespace confluent
kubectl delete  -f prod-cloudproducercmorders.yaml  --namespace confluent
kubectl delete  -f dr-cloudconsumercmcustomers-primary.yaml  --namespace confluent
kubectl delete  -f dr-cloudconsumercmcustomers-secondary.yaml  --namespace confluent
# all pods should be terminated or in termination
echo "*************************** PODS *******************************"
kubectl get pods -n confluent
# Secrets
echo "*************************** SECRETS *******************************"
kubectl get secrets -n confluent
kubectl delete secret kafka-client-consumer-config-secure -n confluent
kubectl delete secret kafka-client-producer-config-secure -n confluent
kubectl delete secret dr-kafka-client-producer-config-secure -n confluent
kubectl delete secret dr-kafka-client-consumer-config-secure -n confluent
kubectl delete secret dr-kafka-client-consumer-config-secure-primary  -n confluent
kubectl delete secret dr-kafka-client-producer-config-secure-primary -n confluent
kubectl delete secret dr-kafka-client-producer-config-secure-secondary -n confluent
kubectl delete secret dr-kafka-client-consumer-config-secure-secondary -n confluent
echo "*************************** SECRETS *******************************"
kubectl get secrets -n confluent
echo
echo "**********************************************************"
echo "All Clients and secrets deleted."