#!/bin/bash

pwd > basedir
export BASEDIR=$(cat basedir)/..
echo $BASEDIR

# form parameter
export consumerkey=${1}
export consumersecret=${2}
export producerkey=${3}
export producersecret=${4}
export bootstrap=${5}
export groupid=${6}
export appmanid=${7}
export appmanidkind=${8}
export appmanidapiversion=${9}
export consumerid=${10}
export consumeridkind=${11}
export consumeridapiversion=${12}
export producerid=${13}
export produceridkind=${14}
export produceridapiversion=${15}
export clusterid=${16}
export endpoint=${17}
export appmanagerkey=${18}
export appmanagersecret=${19}
export source_envid=${20}
export cluster_source_id=${21}

# From Output
#export consumerkey=$(echo -e "$(terraform output -raw consumer_key)")
#export consumersecret=$(echo -e "$(terraform output -raw consumer_secret)")
#export producerkey=$(echo -e "$(terraform output -raw producer_key)")
#export producersecret=$(echo -e "$(terraform output -raw producer_secret)")
#export bootstrap=$(echo -e "$(terraform output -raw cc_kafka_cluster_bootsrap)")
#export groupid=$(echo -e "$(terraform output -raw consumer_group)")
#export appmanid=$(echo -e "$(terraform output -raw appmanid)")
#export appmanidkind=$(echo -e "$(terraform output -raw appmanidkind)")
#export appmanidapiversion=$(echo -e "$(terraform output -raw appmanidapiversion)")
#export consumerid=$(echo -e "$(terraform output -raw consumerid)")
#export consumeridkind=$(echo -e "$(terraform output -raw consumeridkind)")
#export consumeridapiversion=$(echo -e "$(terraform output -raw consumeridapiversion)")
#export producerid=$(echo -e "$(terraform output -raw producerid)")
#export produceridkind=$(echo -e "$(terraform output -raw produceridkind)")
#export produceridapiversion=$(echo -e "$(terraform output -raw produceridapiversion)")

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
group.id=$groupid
auto.offset.reset=latest
default.api.timeout.ms=300000" > ../client_consumer.properties

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
delivery.timeout.ms=120000
retries=2147483647
acks=all" > ../client_producer.properties

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
default.api.timeout.ms=300000" >  ../kafkatools_consumer.properties

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
acks=all" >  ../kafkatools_producer.properties

cp env-source ../../Part2/cold-restore/env-source
# Switch from prod to dr envionment
sed -i -e 's/# export TF_VAR_environment_id/## /g' ../../Part2/cold-restore/env-source
sed -i -e 's/export TF_VAR_environment_id/# Prod Env /g' ../../Part2/cold-restore/env-source
sed -i -e 's/## /export TF_VAR_environment_id/g' ../../Part2/cold-restore/env-source

# Add Service Accounts
echo "# Service Accounts
export TF_VAR_cmapp_manager_id=$appmanid
export TF_VAR_cmapp_manager_kind=$appmanidkind
export TF_VAR_cmapp_manager_api_version=$appmanidapiversion
export TF_VAR_cmapp_consumer_id=$consumerid
export TF_VAR_cmapp_consumer_kind=$consumeridkind
export TF_VAR_cmapp_consumer_api_version=$consumeridapiversion
export TF_VAR_cmapp_producer_id=$producerid
export TF_VAR_cmapp_producer_kind=$produceridkind
export TF_VAR_cmapp_producer_api_version=$produceridapiversion
export TF_VAR_source_bootstrap=$bootstrap
export TF_VAR_source_cluster_id=$clusterid
export TF_VAR_source_endpoint=$endpoint
export TF_VAR_source_appmanager_key=$appmanagerkey
export TF_VAR_source_appmanager_secret=$appmanagersecret
export TF_VAR_source_envid=$source_envid
export TF_VAR_cluster_source_id=$cluster_source_id" >> ../../Part2/cold-restore/env-source

# Copy env File to active Passive Setup
cp ../../Part2/cold-restore/env-source ../../Part3/active-passive/env-source

echo "properties files created"

# Client 1:
# Start client in k8s environment (in my case my own Raspberry k3s cluster) (default)
# Deploy secrets for consumer
kubectl create secret generic kafka-client-consumer-config-secure --from-file=../kafkatools_consumer.properties --namespace confluent
kubectl create secret generic kafka-client-producer-config-secure --from-file=../kafkatools_producer.properties --namespace confluent
# Deploy Producer
kubectl apply -f ../cloudproducercmorders.yaml --namespace confluent
kubectl apply -f ../cloudproducercmcustomers.yaml --namespace confluent
kubectl apply -f ../cloudproducercmproducts.yaml --namespace confluent
# Deploy Consumer
kubectl apply -f ../cloudconsumercmorders.yaml --namespace confluent
kubectl apply -f ../cloudconsumercmcustomers.yaml --namespace confluent
kubectl apply -f ../cloudconsumercmproducts.yaml --namespace confluent

# Client 2:
# Start Terminal for Shell Client (COMMENTED)
#echo ""
#echo "Start Clients from demo...."
#open -a iterm
#sleep 10
#osascript ../00_terminal.scpt $BASEDIR

