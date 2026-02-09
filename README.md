# WEKA On OpenShift

This README explains the steps to be taken to deploy WEKA on OpenShift.

[WEKA](https://www.weka.io/) is a high-performance filesystem that is fully containerized. Deploy and maintain storage clusters using the [WEKA Operator](https://docs.weka.io/kubernetes/composable-clusters-for-multi-tenancy-in-kubernetes). Clusters are YAML-based, making automation a reality.

[OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) is an enterprise-grade container orchestrator, built and maintained by Red Hat.
    
# PREREQUISITES

- A working OpenShift cluster. A non-Hosted Control Plane cluster is required.
  - 6 nodes recommended (3 control plane + 3 worker nodes).
  - Minimum 12 vCPUs per node (16 recommended).
- Access to host ports 14000 - 40000. If using a cloud service provider like AWS, add rules in appropriate Security Groups.

## SUPPORTED OPENSHIFT VERSIONS AND DEPLOYMENTS
Versions `4.17` and above are known to work with WEKA.

Self-managed OpenShift installs are known to work with WEKA. Bare-metal deployments and user provisioned infrastructure on clouds fall in this category.

Fully-managed OpenShift installs (ROSA, ARO, OpenShift on IBM Cloud, OpenShift Dedicated) are NOT known to work. This is due to lack of master node access.

>[!WARNING]
> Hosted Control Plane clusters do not work, on account of certain required CRDs not being exposed (such as `MachineConfig`), making it hard to update HugePagesConfig.

## SUPPORTED HOST OPERATING SYSTEMS
Ubuntu and CoreOS.
OpenShift uses CoreOS by default.

## SUPPORTED WEKA VERSIONS
Versions `v1.9.0` and later are known to work with OpenShift.

It is **always** recommended to use the most recent available version of the WEKA Operator. Releases are published here: <https://get.weka.io/ui/operator>.

# STEPS TO DEPLOY WEKACLUSTER

Assuming a working OpenShift cluster is available, here are the steps to deploy a wekaCluster.

## 0.1 Make Master nodes scheduleable
For workloads on Master nodes that require access to WEKA storage, this makes sense.

```
$ oc edit schedulers.config.openshift.io cluster
Make mastersSchedulable: true
```

## 0.2 Update hugePages config on worker and master nodes
As described in the [docs](https://docs.weka.io/kubernetes/weka-operator-deployments#kubernetes-cluster-and-node-requirements), set the desired number of hugePages on all nodes in the OpenShift cluster.

```
$ oc create -f worker-hpc.yaml
$ oc create -f master-hpc.yaml
```

## 1. Deploy WEKA Operator v1.9.0 or newer:
Use Helm to install the WEKA operator.

```
$ helm upgrade --create-namespace \
    --install weka-operator oci://quay.io/weka.io/helm/weka-operator \
    --namespace weka-operator-system \
    --version v1.9.0 \
    --set csi.installationEnabled=true
```
Upon deploying, you should observe the following output:
```
$ helm upgrade --create-namespace \
    --install weka-operator oci://quay.io/weka.io/helm/weka-operator \
    --namespace weka-operator-system \
    --version v1.9.0 \
    --set csi.installationEnabled=true
Release "weka-operator" does not exist. Installing it now.
Pulled: quay.io/weka.io/helm/weka-operator:v1.9.0
Digest: sha256:3f63b16a7fba5ded2a2324a2a47ab8edcfe29fe66146f3bd8fd29240ed0dd6b4

I0120 13:22:06.783978    4819 warnings.go:110] "Warning: would violate PodSecurity \"restricted:latest\": privileged (container \"node-agent\" must not set securityContext.privileged=true), allowPrivilegeEscalation != false (container \"node-agent\" must set securityContext.allowPrivilegeEscalation=false), unrestricted capabilities (container \"node-agent\" must set securityContext.capabilities.drop=[\"ALL\"]), restricted volume types (volumes \"weka-persistence\", \"dev\", \"host-run\" use restricted volume type \"hostPath\"), runAsNonRoot != true (pod must not set securityContext.runAsNonRoot=false), seccompProfile (pod or container \"node-agent\" must set securityContext.seccompProfile.type to \"RuntimeDefault\" or \"Localhost\")"
I0120 13:22:06.828004    4819 warnings.go:110] "Warning: would violate PodSecurity \"restricted:latest\": runAsNonRoot != true (pod must not set securityContext.runAsNonRoot=false)"
I0120 13:22:06.972782    4819 warnings.go:110] "Warning: unknown field \"allowedVolumeTypes\""
I0120 13:22:06.974912    4819 warnings.go:110] "Warning: unknown field \"allowedVolumeTypes\""
I0120 13:22:06.985514    4819 warnings.go:110] "Warning: unknown field \"allowedVolumeTypes\""
I0120 13:22:06.985572    4819 warnings.go:110] "Warning: unknown field \"allowedVolumeTypes\""
NAME: weka-operator
LAST DEPLOYED: Tue Jan 20 13:22:02 2026
NAMESPACE: weka-operator-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Chart: weka-operator
Release: weka-operator
```
Confirm the operator is up and running:
```
$ oc get pods -n weka-operator-system

NAME                                                READY   STATUS    RESTARTS   AGE
weka-operator-controller-manager-5ddf4d4b8d-8b49z   2/2     Running   0          30s
weka-operator-node-agent-f48t5                      1/1     Running   0          30s
weka-operator-node-agent-fst52                      1/1     Running   0          30s
weka-operator-node-agent-r2w7h                      1/1     Running   0          30s
weka-operator-node-agent-v7qnd                      1/1     Running   0          30s
```

You should see 1 controller pod + `n` node pods (where `n` equals number of OpenShift nodes)

## 2. Elevate permissions of `weka-operator-controller-manager` Service Account
Necessary to sign and discover storage drives attached to each OpenShift node.
Run the following command:
```
$ oc adm policy add-scc-to-user privileged -z
weka-operator-controller-manager

clusterrole.rbac.authorization.k8s.io/system:openshift:scc:privileged added: "weka-operator-controller-manager"
```

## 3. Create wekaPolicy
A wekaPolicy is used to identify the drives that will be a part of the storage cluster.
```
$ oc create -f wekapolicy.yaml
```

Confirm the wekaPolicy worked as expected:

```
$ oc describe node | grep weka.io/
```
Each node should have the following annotations added to them after a successful wekaPolicy execution:
- `weka.io/weka-drives`
- `weka.io/sign-drives-hash`
- `weka.io/discovery.json`

You can confirm this by executing the following command, which returns all nodes that have the `weka.io/weka-drives` annotation applied. For example:

```
$ oc get nodes -o json | jq -r '.items[] | select(.metadata.annotations."weka.io/weka-drives") | .metadata.name'

ip-10-0-12-29.us-east-2.compute.internal
ip-10-0-30-6.us-east-2.compute.internal
ip-10-0-39-13.us-east-2.compute.internal
ip-10-0-49-167.us-east-2.compute.internal
ip-10-0-52-68.us-east-2.compute.internal
ip-10-0-56-107.us-east-2.compute.internal
```

You can also check the output of `oc get wekaPolicy --all-namespaces`. A successful policy run is indicated by its `Status` field.

## 4. Create a wekaCluster
You are now ready to create a cluster! Execute the following command:
```
$ oc create -f wekacluster.yaml
```
Observe the progression of cluster deployment with:
```
$ watch oc get pods,wekacluster -n weka-operator-system
```
wekaCluster should progress through the following stages: `Init`, `ReadyForIO`, `StartingIO`, and `Ready`

The wekaCluster is installed and ready when it reports the `Ready` status.

```
$ oc get wekacluster
NAME          STATUS   CLUSTER ID                             CCT(A/C/D)   DCT(A/C/D)   DRVS(A/C/D)
cluster-dev   Ready    99ac745a-ecf9-4a67-85ce-80b9a7132442   6/6/6        6/6/6        6/6/6
```

## 5. Create a wekaClient and access the wekaCluster
To access the cluster, a wekaClient must be created. Creating a wekaClient kicks off the CSI driver deployment.
Use the command below to deploy a wekaClient:
```
$ oc create -f wekaclient-def.yaml
```
>[!WARNING]
> Ensure `udpMode: true` in your wekaClient definition.

> [!WARNING]
> Version `v1.9.0` of WEKA operator requires a fix for CSI deployments to succeed.
> `weka-operator-manager-role` ClusterRole must be patched to address a permission issue.
> ```
> $ oc edit clusterrole weka-operator-manager-role
> ```
> Add the following block to your clusterRole definition:
> ```
> - apiGroups:
>   - apps
>   resources:
>   - deployments/finalizers
>   verbs:
>   - update
>   - patch
> ```

## 6. Confirm CSI driver is up and running
```
$ oc get csidriver
NAME                                       ATTACHREQUIRED   PODINFOONMOUNT   STORAGECAPACITY   TOKENREQUESTS   REQUIRESREPUBLISH   MODES        AGE
cluster-dev.weka-operator-system.weka.io   true             true             false             <unset>         false               Persistent   33m
```
```
 $ oc get deployment
NAME                                                   READY   UP-TO-DATE   AVAILABLE   AGE
cluster-dev-management-proxy                           2/2     2            2           63m
cluster-dev-weka-operator-system-weka-csi-controller   2/2     2            2           20m
monitoring-cluster-dev                                 0/1     1            0           68m
weka-operator-controller-manager                       1/1     1            1           96m
```
## 7. Create a Pod and PVC
Finally, provision storage for a pod from the wekaCluster.
```
oc create -f pvcandpod.yaml
```
```
 oc get pvc,pod -n default
NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS                                    VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/pvc-weka   Bound    pvc-483a1f1f-cf28-4d4d-b9f7-6543241cae9f   5Gi        RWX            weka-cluster-dev-weka-operator-system-default   <unset>                 21s

NAME           READY   STATUS    RESTARTS   AGE
pod/pod-weka   1/1     Running   0          21s
```
The pod is up and running! You are ready for more serious workloads.
