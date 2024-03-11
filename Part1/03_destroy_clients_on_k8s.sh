#!/bin/bash
echo "****************** PODS ***********************"
kubectl get pods -n confluent
kubectl delete  -f cloudconsumercmorders.yaml --namespace confluent
kubectl delete  -f cloudproducercmorders.yaml --namespace confluent
kubectl delete  -f cloudconsumercmproducts.yaml --namespace confluent
kubectl delete  -f cloudproducercmproducts.yaml --namespace confluent
kubectl delete  -f cloudproducercmcustomers.yaml --namespace confluent
kubectl delete  -f cloudconsumercmcustomers.yaml  --namespace confluent
# all pods should be terminated or in termination
echo "****************** PODS ***********************"
kubectl get pods -n confluent

# Secrets
echo "****************** SECRETS ***********************"
kubectl get secrets -n confluent
kubectl delete secret kafka-client-consumer-config-secure -n confluent
kubectl delete secret kafka-client-producer-config-secure -n confluent
echo "****************** SECRETS ***********************"
kubectl get secrets -n confluent
echo "*****************************************"
echo "Alle clients and secrets deleted"