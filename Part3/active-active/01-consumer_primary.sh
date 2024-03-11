#!/bin/bash
# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Consume from Confluent Cloud primary.cmcustomers topic\007"'
echo -e "\033];Consume from Confluent Cloud primary.cmcustomers topic\007"

source env-destination

# Consume raw events Terminal 1
echo "Consume from Confluent Cloud primary.cmcustomers topic: "
kafka-console-consumer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' ../kafkatools_consumer_primary.properties | cut -d'=' -f 2) --topic cmcustomers --consumer.config ../kafkatools_consumer_primary.properties