#!/bin/bash
# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Produce to Confluent Cloud cmorders topic\007"'
echo -e "\033];Produce to Confluent Cloud cmorders topic\007"

# Consume raw events Terminal 2
echo "Produce to Confluent Cloud cmorders topic: "
echo "# Sample records:"
echo "# {"number":1,"date":18500,"shipping_address":"899 W Evelyn Ave, Mountain View, CA 94041, USA","cost":15.00}"
echo "# {"number":2,"date":18501,"shipping_address":"1 Bedford St, London WC2E 9HG, United Kingdom","cost":5.00}"
echo "# {"number":3,"date":18502,"shipping_address":"3307 Northland Dr Suite 400, Austin, TX 78731, USA","cost":10.00}"
#kafka-console-producer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' kafkatools_producer.properties | cut -d'=' -f 2) --topic cmorders \
# --producer.config ./kafkatools_producer.properties

for x in {1..1000}; do echo "{"number":$x,"date":18500$x,"shipping_address":"shipping street $x, $x Shippping-City, Global","cost":$x}"; sleep 2; done | kafka-console-producer --bootstrap-server  $(awk '/bootstrap.servers=/{print $NF}' kafkatools_producer.properties | cut -d'=' -f 2) --topic cmorders \
 --producer.config ./kafkatools_producer.properties

