# Live DR Demo Setup

I divided the Demo in 3 main Parts.
* Part 1: How to split Infra-Team (OrgAdmin) from Product Team (Environment and Cluster Admin). Delegated Administration
* Part 2: How to build after a broken prod cluster, the same cluster into a diffrent CSP and region and failover the clients after a short downtime. Cold restore
* Part 3: Active -> Passive Disaster Recovery setup with Cluster Linking and Failover for clients and switch back. Active-Passive DR Pattern


Welcome to the Desaster Recovery Demo repo. This Demo is splitted into 4 Parts.
1. Part: How to split Infra-Team (OrgAdmin) from Product Team (Environment and Cluster Admin). This is a kind of delegated Administration. And finally in this part we will build a prod-cluster in Confluent Cloud. For cold-restore and active-passive geo-replication setup we will use Basic cluster, active-active geo-replication setup we will use a dedicated cluster type (this is a requirement ofbi-directional cluster links).
2. Part: How to build after a broken prod cluster, the same cluster into a diffrent CSP and region and failover the clients after a short downtime. Cold-Restore. We will build the same cluster in a different location and switch the client to the new cluster automatically by changing the connection details in our client properties (secrets).
3. Part: Active -> Passive Disaster Recovery setup with Cluster Linking and Failover for clients and switch back. Active-Passive DR Pattern. Running a DR Mirror in a differenrt geo location and mirroring only Gold SLA Apps (with high HA requirements) and switch clients when a break occurs. We will use Cluster Linking.
4. Part (not yet covered here): Active-Active setup. Having a two Cluster setup with bi-direktional cluster link. Please use this [playground](https://github.com/ogomezso/disaster-recovery-playground) in the meantime.

We will work mainly in Confluent Cloud. All clients are simple kafka-tools clients and are running in my k3s cluster lab, running with Confluent for Kubernetes.
To be honest this is the best k3s lab ever. I don't want to miss it, it make so much easier.
If do not have a k8s cluster running, I did also put some client shell scripts into this repo see folder `Part1`.

# pre-reqs for running this lab - Live-DR-Demos

* Confluent cli installed on your desktop. [Install Confluent cli](https://docs.confluent.io/confluent-cli/current/install.html)
* Confluent Cloud Account
* One Confluent Cloud API Key as OrgAdmn with service Account aligned (tf_runner, im my case tf_cmrunner with Organization Admin Role binded)
    1. Create a [service account](https://docs.confluent.io/cloud/current/access-management/identity/service-accounts.html) called tf_runnerin Confluent Cloud
    2. Assign the OrganizationAdmin [role](https://docs.confluent.io/cloud/current/access-management/access-control/rbac/overview.html#organizationadmin) to the tf_runner service account
    3. Create a [Cloud API Key](https://docs.confluent.io/cloud/current/access-management/authenticate/api-keys/api-keys.html#cloud-cloud-api-keys) for the tf_runner service account
* terraform installed (version 1.6.6)
* Kubernetes Cluster with Confluent for Kubernetes Operator (version 2.7), [see my Raspberry PI setup](https://github.com/ora0600/cfk-on-rpi)
* Optional if you use K8s: Install reloader on K8s for switching the clients automatically when secrets are changed, see coce below 

```bash
# install reloader on default namespace in your k8s cluster
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
``` 

# Execution of the Live-DR-Demo

Please clone this repo onto your desktop.
```bash
# move into your into your favorite folder. In my case it is Demos
cd ~/Demos
git clone https://github.com/ora0600/confluent-live-dr-demo.git
cd confluent-live-dr-demo
```

With the clone and all the pre-reqs you have all you need to execute the demos.

1. Part: Service Accounts, Prod-Cluster. Start [here](part1.md)
2. Part: Cold-Restore. Start [here](part2.md)
3. Part: Active -> Passive Disaster Recovery setup. Start [here](part3.md)
4. Part (not yet covered here): Please use this [playground](https://github.com/ogomezso/disaster-recovery-playground) in the meantime.

All labs/demos are finished. Do not forget to delete everything.

# Destroy
Destroy the complete demo:

# Destroy k3s
First the pods and secrets:

```bash
cd Part3/active-passive
kubectl delete -f ../../Part1/cloudproducercmorders.yaml --namespace confluent
# Deploy Consumer
kubectl delete  -f ../../Part1/cloudconsumercmorders.yaml --namespace confluent
# Secrets
kubectl delete secret kafka-client-consumer-config-secure -n confluent
kubectl delete secret kafka-client-producer-config-secure -n confluent
``` 
## Shutdown cluster
```bash
ssh -i ~/keys/k3s-key ubuntu@cpworker1
sudo shutdown -h now
ssh -i ~/keys/k3s-key ubuntu@cpworker2
sudo shutdown -h now
ssh -i ~/keys/k3s-key ubuntu@cpworker3
sudo shutdown -h now
ssh -i ~/keys/k3s-key ubuntu@cpmaster
sudo shutdown -h now
```

## Destroy passive cluster 

```bash
cd Part3/active-passive/
source env-source
terraform destroy
``` 

## Destroy DR cluster from cold-restore

```bash
cd ../../Part2/cold-restore
source env-source
terraform destroy
``` 

## Destroy Prod Cluster

```bash
cd ../../Part1/02-env-admin-product-team
source env-source
terraform destroy
``` 

## Destroy Env and Env-Manager

```bash
cd ../01-kafka-ops-team
terraform destroy
```

When you got no errors all Confluent Cloud resources should be deleted.

# License
to run Confluent Cloud you need a Confluent Cloud Account. To run Confluent for Kubernetes in your K8s cluster like me, you need a Confluent Platform license (contract or 30-days evaluation key).

# Development-HINT:
<table><tr><td>My simple demo is just for show-case a DR scenario with a really simple case. From a coding perspective it would be better if you structure your IaaS in modules.</td></tr></table>







