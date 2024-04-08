#!/bin/bash

# Start client in k8s environment (in my case my own Raspberry k3s cluster) (default)
# Deploy secrets for consumer
kubectl create secret generic dr-kafka-client-consumer-config-secure --from-file=../kafkatools_consumer.properties --namespace confluent
kubectl create secret generic dr-kafka-client-producer-config-secure --from-file=../kafkatools_producer.properties --namespace confluent
# Deploy Producer
kubectl apply -f ../prod-cloudproducercmorders.yaml --namespace confluent
kubectl apply -f ../prod-cloudproducercmcustomers.yaml --namespace confluent
kubectl apply -f ../prod-cloudproducercmproducts.yaml --namespace confluent
# Deploy Consumer
kubectl apply -f ../prod-cloudconsumercmorders.yaml --namespace confluent
kubectl apply -f ../prod-cloudconsumercmcustomers.yaml --namespace confluent
kubectl apply -f ../prod-cloudconsumercmproducts.yaml --namespace confluent

