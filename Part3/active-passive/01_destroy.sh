#!/bin/bash

# Delete K8s Clients
#kubectl delete -f ../../Part1/cloudproducercmorders.yaml --namespace confluent 2> /dev/null
#kubectl delete -f ../../Part1/cloudconsumercmorders.yaml --namespace confluent 2> /dev/null
#kubectl delete -f ../../Part1/cloudconsumercmcustomers.yaml --namespace confluent 2> /dev/null
#kubectl delete -f ../../Part1/cloudproducercmcustomers.yaml --namespace confluent 2> /dev/null
#kubectl delete -f ../../Part1/cloudconsumercmproducts.yaml --namespace confluent 2> /dev/null
#kubectl delete -f ../../Part1/cloudproducercmproducts.yaml --namespace confluent 2> /dev/null

#kubectl delete secret kafka-client-consumer-config-secure  --namespace confluent
#kubectl delete secret kafka-client-producer-config-secure  --namespace confluent

echo "k3s clients and secrets should be deleted"
kubectl get pods -n confluent
kubectl get secrets -n confluent

# Delete env file
rm env-source
rm env-destination

echo "source env files are deleted".