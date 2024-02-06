#!/bin/bash

# from parameter
export consumerkey=${1}
export consumersecret=${2}
export producerkey=${3}
export producersecret=${4}
export bootstrap=${5}
export groupid=${6}
export appmanid=${7}
export consumerid=${8}
export producerid=${9}

# from output
#export consumerkey=$(echo -e "$(terraform output -raw consumer_key)")
#export consumersecret=$(echo -e "$(terraform output -raw consumer_secret)")
#export producerkey=$(echo -e "$(terraform output -raw producer_key)")
#export producersecret=$(echo -e "$(terraform output -raw producer_secret)")
#export bootstrap=$(echo -e "$(terraform output -raw cc_kafka_cluster_bootsrap)")
#export groupid=$(echo -e "$(terraform output -raw consumer_group)")
#export appmanid=$(echo -e "$(terraform output -raw appmanid)")
#export consumerid=$(echo -e "$(terraform output -raw consumerid)")
#export producerid=$(echo -e "$(terraform output -raw producerid)")

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
group.id=$groupid
auto.offset.reset=latest
default.api.timeout.ms=300000" > ../../Part1/client_consumer.properties

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
delivery.timeout.ms=120000
retries=2147483647
acks=all" > ../../Part1/client_producer.properties

echo "# Required connection configs for Kafka consumer
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$consumerkey' password='$consumersecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
group.id=$groupid
auto.offset.reset=latest
default.api.timeout.ms=300000" >  ../../Part1/kafkatools_consumer.properties

echo "# Required connection configs for Kafka producer
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$producerkey' password='$producersecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
delivery.timeout.ms=120000
retries=2147483647
acks=all" >  ../../Part1/kafkatools_producer.properties

# redeploy secrets in k3s
kubectl create secret generic kafka-client-consumer-config-secure --save-config --dry-run=client --from-file=../../Part1/kafkatools_consumer.properties -o yaml | kubectl apply -f -
kubectl create secret generic kafka-client-producer-config-secure --save-config --dry-run=client --from-file=../../Part1/kafkatools_producer.properties -o yaml | kubectl apply -f -

echo "properties files created"
echo "in k8s clients will be restart automatically (or Move to iterm and restart clients in folder : cd ../../Part1/)"
