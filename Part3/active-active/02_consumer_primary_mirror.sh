#!/bin/bash
# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Consumer to Confluent Cloud primary.mirror-cmcustomers topic\007"'
echo -e "\033];Consumer to Confluent Cloud primary.mirror-cmcustomers topic\007"

# Consume raw events Terminal 2
echo "Consume from Confluent Cloud primary.mirror-cmcustomers topic: "
kafka-console-consumer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' ../kafkatools_consumer_primary.properties | cut -d'=' -f 2) --topic mirror-cmcustomers \
 --consumer.config ../kafkatools_consumer_primary.properties
