#!/bin/bash
# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Consume to Confluent Cloud secondary.cmcustomers topic\007"'
echo -e "\033];Consume to Confluent Cloud secondary.cmcustomers topic\007"

# Consume raw events Terminal 2
echo "Consume from Confluent Cloud secondary.cmcustomers topic: "
kafka-console-consumer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' ../kafkatools_consumer_secondary.properties | cut -d'=' -f 2) --topic cmcustomers \
 --consumer.config ../kafkatools_consumer_secondary.properties
