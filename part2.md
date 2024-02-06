# Part 2: Do cold restore

Build a new  Cluster with same resources and switch clients to new cluster. For this DR case we do not need any data replication. This is in most cases because the leading systems are integrated into Kafka/Confluent Cloud. Our clients simulate this.

Source the environment variables, including all Service Accounts.
```bash
cd ../../Part2/cold-restore/
# We will now use the cmprod-dr environment 
# Source env-cars
source env-source
```

Build new cluster in cmprod-dr environment and generate new Keys for the client Service Accounts:

```bash
terraform init
terraform plan
terraform apply --auto-approve
# Apply complete! Resources: 11 added, 0 changed, 0 destroyed.
# Outputs:
# appmanid = "sa-1"
# cc_kafka_cluster_bootsrap = "SASL_SSL://pkc-75m1o.europe-west3.gcp.confluent.cloud:9092"
# consumer_group = "cmgroup"
# consumer_key = "X5XXXXXXX"
# consumer_secret = <sensitive>
# consumerid = "sa-2"
# manager_key = "45XXXXX"
# manager_secret = <sensitive>
# producer_key = "JJXXXXXX"
# producer_secret = <sensitive>
# producerid = "sa-3"
# resource-ids = <sensitive>
``` 

The `terraform apply` will generate new client prpoperties files and load them into k8s secrets. So to say do a rewrite. The reloader then starts the clients automatically. And all clients running now with DR Cluster.
Clients writing now into dr cluster and reading from it.
Check: 

* in Cloud UI: go to cluster in cmprod-dr environment -> Topic and check messages in cmorders
* use kubectl tools:

```bash
# Are the pods running (producer and consumer)?
kubectl get pods -n confluent
# NAME                                  READY   STATUS             RESTARTS      AGE
# confluent-operator-6b9f68dc5c-rl62w   1/1     Running            7 (19h ago)   64d
# cloudconsumercmorders-0               1/1     Running            0             2m40s
# cloudproducercmproducts-0             1/1     Running            0             2m10s
# cloudproducercmorders-0               1/1     Running            0             2m10s
# cloudproducercmcustomers-0            1/1     Running            0             2m10s
# cloudconsumercmproducts-0             0/1     CrashLoopBackOff   4 (18s ago)   2m39s
# cloudconsumercmcustomers-0            0/1     CrashLoopBackOff   4 (16s ago)   2m40s
# Show heich data the consumer can now read
kubectl logs cloudconsumercmorders-0 -n confluent
``` 

2 Consumers failed, because the restore do cober only one topic cmorders.
Consumer and producer running now in cmprod-dr cluster.

## If you continue this demo with the next lab:

If you want to continue with Part3 - the active-passsive setup - please switch the clients before continue. 
Please do the following.
```bash
cd ../../Part1/02-env-admin-product-team/
# Run shell script to load the client properties from prodcluster into k8s secrets.
./01_switchback_client.properties.sh 
# Kubectl : all pods should run
kubectl get pods -n confluent
``` 

Clients are running on cmprod_cluster now.

# Development-HINT:
<table><tr><td>My simple demo is just for show-case a DR scenario with a really simple case. From a coding perspective it would be better if you structure your IaaS in modules.</td></tr></table>

Back to [main Readme](ReadMe.md)