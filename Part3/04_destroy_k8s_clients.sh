#!/bin/bash

echo "*************************** PODS *******************************"
kubectl get pods -n confluent
kubectl delete  -f prod-cloudproducercmtopic.yaml  --namespace confluent
kubectl delete  -f prod-cloudconsumercmtopic.yaml  --namespace confluent
kubectl delete  -f  prod-cloudconsumercmtopic-mirror.yaml --namespace confluent

# all pods should be terminated or in termination
echo "*************************** PODS *******************************"
kubectl get pods -n confluent
# Secrets
echo "*************************** SECRETS *******************************"
kubectl get secrets -n confluent
kubectl delete secret prod-cloudconsumercmtopic-config-secure -n confluent
kubectl delete secret prod-cloudproducercmtopic-config-secure -n confluent
kubectl delete prod-cloudconsumercmtopic-mirror-config-secure -n confluent
echo "*************************** SECRETS *******************************"
kubectl get secrets -n confluent
echo
echo "**********************************************************"
echo "All Clients and secrets deleted."