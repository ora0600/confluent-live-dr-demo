# Active-Passive Cluster setup

Prod cluster is running and Environments (cmrprod, cmprod-dr) still exists.
If not, start again from the beginning, see [Part1](part1.md).

In this lab we will a passive DR Cluster with Cluster Linking. This cluster is from type dedicated and costs more money than basic. Please check [price list](https://www.confluent.io/confluent-cloud/pricing/). 

Execute Part3 and new cluster is created:

```bash
cd ../../Part3/active-passive/
source env-source
terraform init
terraform plan
terraform apply --auto-approve
```

A new dedicated cluster with Public network endpoints was created, a test topic in source cluster , a cluster link between both cluster and a mirror topic on the test topic.

The idea now is to not copy the complete content from prodcluster to passive DR cluster. We have special SLA for special resources. We call is Gold SLA.
There are couple resources as GOLD marked and documentes in `cat scripts/sla_gold_topics.txt`. Only these resources will be mirrored in DR cluster.

Running the SLA based DR Plan: 
In our case we do have only one topic which needs to be geo-replicated because of high HA requirements.

```bash
./scripts/00_create_mirror_topics.sh
``` 

Now, you can play a little bit in the Cloud UI. This is quite interesting. Check:
* Cluster Linking Menu (left side)
* Show Topics in DR Cluster, is data coming from cmprod_cluster?
* etc.

Check producer is the data produced is the same in passive_cmprod_cluster.cmorders topic:
```bash
kubectl logs cloudconsumercmorders-0 -n confluent
```

Now, we have situation after failover. In a cloud native environment we would recommend to fail forward. This means

* the DR region becomes the new Primary region.
*  cloud regions offer identical service
* all applications & data systems are now in the DR region
* failing back would introduce risk with little benefit

To fail forward, simply:
* Delete topics on original cluster (or spin up new cluster)
* Establish cluster link in reverse direction

Another Alternative would be to fail back to prod-cluster from DR-cluster.

1. Delete topics on Primary cluster (or spin up a new cluster)
2. Establish a cluster link in the reverse direction
3. When Primary has caught up, migrate producers & consumers back:
    a. Stop clients
    b. promote mirror topic(s)
    c. Restart clients pointed at Primary cluster


back to [main Readme](ReadME.md)