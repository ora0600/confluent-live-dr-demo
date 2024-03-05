#!/bin/bash

# Copy properties files from primary
cp ../kafkatools_consumer_primary.properties ../kafkatools_consumer.properties
cp ../kafkatools_producer_primary .properties ../kafkatools_producer.properties

# Deploy olds secrets back
kubectl create secret generic kafka-client-consumer-config-secure --save-config --dry-run=client --from-file=../kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic kafka-client-producer-config-secure --save-config --dry-run=client --from-file=../kafkatools_producer.properties -o yaml | kubectl apply -f -

echo "Clients should now switch, run on primary cluster again. Switch finished."

