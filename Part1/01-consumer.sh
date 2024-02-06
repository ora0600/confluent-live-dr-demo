#!/bin/bash
# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Consume from Confluent Cloud cmorders topic\007"'
echo -e "\033];Consume from Confluent Cloud cmorders topic\007"

# Consume raw events Terminal 1
echo "Consume from Confluent Cloud cmorders topic: "
kafka-console-consumer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' kafkatools_consumer.properties | cut -d'=' -f 2) --topic cmorders \
 --consumer.config ./kafkatools_consumer.properties