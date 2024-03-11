# Live DR Demo Setup

Welcome to the Disaster Recovery Demo repo. This Demo is split into 4 Parts.

1. Part: **delegated Administration**: How to split Infra-Team (OrgAdmin) from Product Team (Environment and Cluster Admin). This is a kind of delegated Administration. And finally in this part we will build a prod-cluster in Confluent Cloud. For cold-restore and active-passive geo-replication setup we will use Basic cluster, active-active geo-replication setup we will use a dedicated cluster type (this is a requirement of bi-directional cluster links).
2. Part: **Cold Restore**: How to build after a broken prod cluster, the same cluster into a different CSP and region and failover the clients after a short downtime. Cold-Restore. We will build the same cluster in a different location and switch the client to the new cluster automatically by changing the connection details in our client properties (secrets).
3. Part: **DR Application Design**: 
   * Create 2 dedicated Clusters with cluster links as product team
   * Active -> Passive Disaster Recovery setup with Cluster Linking and Failover for clients and switch back. Active-Passive DR Pattern. Running a DR Mirror in a different geo location and mirroring only Gold SLA Apps (with high HA requirements) and switch clients when a break occurs. We will use Cluster Linking.
   * Active -> Active setup. Having a two Cluster setup with bi-directional cluster link. Delete topic pattern.

We will work mainly in Confluent Cloud. All clients are simple kafka-tools clients and are running in my [k3s cluster lab](https://github.com/ora0600/cfk-on-rpi), running with Confluent for Kubernetes.
If do not have a k8s cluster running, I did also put some client shell scripts into this repo see folder `Part1`.

## pre-reqs for running this lab - Live-DR-Demos

* Confluent cli installed on your desktop. [Install Confluent cli](https://docs.confluent.io/confluent-cli/current/install.html)
* Confluent Cloud Account
* One Confluent Cloud API Key as OrgAdmin with service Account aligned (tf_runner, im my case tf_cmrunner with Organization Admin Role alignment)
    1. Create a [service account](https://docs.confluent.io/cloud/current/access-management/identity/service-accounts.html) called tf_runner in Confluent Cloud
    2. Assign the Organization Admin [role](https://docs.confluent.io/cloud/current/access-management/access-control/rbac/overview.html#organizationadmin) to the tf_runner service account
    3. Create a [Cloud API Key](https://docs.confluent.io/cloud/current/access-management/authenticate/api-keys/api-keys.html#cloud-cloud-api-keys) for the tf_runner service account
* terraform installed (version 1.6.6)
* Kubernetes Cluster with Confluent for Kubernetes Operator (version 2.7), [see my Raspberry PI setup](https://github.com/ora0600/cfk-on-rpi)
  * Install reloader on K8s for switching the clients automatically when secrets are changed, see code below 

```bash
# install reloader on default namespace in your k8s cluster
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml
```

## Execution of the Live-DR-Demo

Please clone this repo onto your desktop.

```bash
# move into your into your favorite folder. In my case it is Demos
cd ~/<your Path>
git clone https://github.com/ora0600/confluent-live-dr-demo.git
cd confluent-live-dr-demo
```

With the clone and all the pre-reqs you have all you need to execute the demos.

* **Cold Restore**:
  - [x] Part 1: Service Accounts, Prod-Cluster. Start [here](part1.md)
  - [x] Part 2: Cold-Restore. Start [here](part2.md)
* **Cluster Setup with DR design for Apps**:
  - [x] Part 3: Build dedicated clusters setup with one-directional cluster link (active/passive) and bidirectional cluster links (active/active), Start [here](part3.md)
  - [x] Part 3: Active -> Passive Disaster Recovery setup. Start [here](part3.md#active-passive-cluster-setup)
  - [x] Part 3: active-active setup. Start [here](part3.md#active-passive-cluster-setup)

When all labs/demos are finished, do not forget to delete everything.

## License

to run Confluent Cloud you need a Confluent Cloud Account. To run Confluent for Kubernetes in your K8s cluster like me, you need a Confluent Platform license (contract or 30-days evaluation key).

## Development-HINT:

<table><tr><td>My simple demo is just for show-case a DR scenario with a really simple case. From a coding perspective it would be better if you structure your IaaS in modules especially for a cold-restore point of view.</td></tr></table>







