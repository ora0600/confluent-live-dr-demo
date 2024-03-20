#!/bin/bash

# form parameter
export consumerkey=${1}
export consumersecret=${2}
export consumersecondarykey=${3}
export consumersecondarysecret=${4}
export producerkey=${5}
export producersecret=${6}
export producersecondarykey=${7}
export producersecondarysecret=${8}
export bootstrap=${9}
export bootstrap_secondary=${10}
export groupid=${11}
export clusterid=${12}
export endpoint=${13}
export clusterid_secondary=${14}
export endpoint_secondary=${15}
export appmanagerkey=${16}
export appmanagersecret=${17}
export appmanagerkey_secondary=${18}
export appmanagersecret_secondary=${19}
export source_envid=${20}
export consumer_said=${21}
export producer_said=${22}

# From Output
#export consumerkey=$(echo -e "$(terraform output -raw consumer_key)")
#export consumersecret=$(echo -e "$(terraform output -raw consumer_secret)")
#export producerkey=$(echo -e "$(terraform output -raw producer_key)")
#export producersecret=$(echo -e "$(terraform output -raw producer_secret)")
#export bootstrap=$(echo -e "$(terraform output -raw cc_kafka_cluster_bootsrap)")
#export groupid=$(echo -e "$(terraform output -raw consumer_group)")

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
group.id=$groupid-primary
auto.offset.reset=latest
default.api.timeout.ms=300000" > ../client_consumer_primary.properties

echo "
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.mechanisms=PLAIN
sasl.username=$consumerkey
sasl.password=$consumersecret
session.timeout.ms=45000
delivery.timeout.ms=120000
retries=2147483647
acks=all" > ../client_producer_primary.properties

echo "# Required connection configs for Kafka consumer primary
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$consumerkey' password='$consumersecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
group.id=$groupid-primary
auto.offset.reset=latest
default.api.timeout.ms=300000" >  ../kafkatools_consumer_primary.properties
cp ../kafkatools_consumer_primary.properties ../kafkatools_consumer.properties

echo "# Required connection configs for Kafka consumer secondary
bootstrap.servers=$bootstrap_secondary
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$consumersecondarykey' password='$consumersecondarysecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
group.id=$groupid-secondary
auto.offset.reset=latest
default.api.timeout.ms=300000" >  ../kafkatools_consumer_secondary.properties


echo "# Required connection configs for Kafka producer primary
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
acks=all" >  ../kafkatools_producer_primary.properties
cp ../kafkatools_producer_primary.properties ../kafkatools_producer.properties

echo "# Required connection configs for Kafka producer secondary
bootstrap.servers=$bootstrap_secondary
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$producersecondarykey' password='$producersecondarysecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
delivery.timeout.ms=120000
retries=2147483647
acks=all" >  ../kafkatools_producer_secondary.properties

# Consumer Offset Monitoring:
echo "# Required connection configs for Kafka consumer offset monitoring primary
bootstrap.servers=$bootstrap
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$consumerkey' password='$consumersecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
group.id=$groupid-primary
default.api.timeout.ms=300000" >  ../kafkatools_prod_consumer_offset_primary.properties

# Consumer Offset Monitoring:
echo "# Required connection configs for Kafka consumer offset monitoring secondary
bootstrap.servers=$bootstrap_secondary
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username='$consumersecondarykey' password='$consumersecondarysecret';
sasl.mechanism=PLAIN
# Required for correctness in Apache Kafka clients prior to 2.6
client.dns.lookup=use_all_dns_ips
# Best practice for higher availability in Apache Kafka clients prior to 3.0
session.timeout.ms=45000
group.id=$groupid-secondary
default.api.timeout.ms=300000" >  ../kafkatools_prod_consumer_offset_secondary.properties

echo "export source_envid=$source_envid
export cluster_source_id=$clusterid
export destination_envid=$source_envid
export cluster_destination_id=$clusterid_secondary
export source_bootstrap=$bootstrap
export destination_bootstrap=$bootstrap_secondary
export groupid=$groupid
export consumer_said=$consumer_said
export producer_said=$producer_said" > ../active-passive/env-destination

echo "export source_envid=$source_envid
export cluster_source_id=$clusterid
export destination_envid=$source_envid
export cluster_destination_id=$clusterid_secondary
export source_bootstrap=$bootstrap
export destination_bootstrap=$bootstrap_secondary
export groupid=$groupid
export consumer_said=$consumer_said
export producer_said=$producer_said" > ../active-active/env-destination


# Copy env File to active Passive Setup
# cp ../../Part2/cold-restore/env-source ../../Part3/02-env-admin-product-team/env-source
# Copy env File to active active Setup
# cp ../../Part2/cold-restore/env-source ../../Part4/active-active/env-source

echo "properties files created"
