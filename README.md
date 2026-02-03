# WEKA On OpenShift
This README explains the steps to be taken to deploy WEKA on OpenShift 4.20 and above.

# PREREQUISITES

- A working OpenShift cluster. A non-HCP cluster is required.
  - 6 nodes recommended (3 control plane + 3 worker nodes).
  - Minimum 12 vCPUs per node (16 recommended).
- Access to host ports 14000 - 40000. If using a cloud service provider like AWS, add rules in appropriate Security Groups.

  *UPDATE: Hosted Control Plane clusters do not work, on account of certain required CRDs not being exposed (such as `MachineConfig`), making it hard to update HugePagesConfig*

# STEPS TO DEPLOY WEKACLUSTER

0.1 Make Master nodes scheduleable. For workloads on Master nodes that require access to WEKA storage, this makes sense.

```
oc edit schedulers.config.openshift.io cluster
Make mastersSchedulable: true
```

0.2 Update hugePages config on worker and master nodes.

```
oc create -f worker-hpc.yaml
oc create -f master-hpc.yaml
```

1. Deploy WEKA Operator v1.9.0 or newer:

```
helm upgrade --create-namespace \
    --install weka-operator oci://quay.io/weka.io/helm/weka-operator \
    --namespace weka-operator-system \
    --version v1.9.0 \
    --set csi.installationEnabled=true
```
Upon deploying, you should observe the following output:
```
helm upgrade --create-namespace \
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
oc get pods -n weka-operator-system

NAME                                                READY   STATUS    RESTARTS   AGE
weka-operator-controller-manager-5ddf4d4b8d-8b49z   2/2     Running   0          30s
weka-operator-node-agent-f48t5                      1/1     Running   0          30s
weka-operator-node-agent-fst52                      1/1     Running   0          30s
weka-operator-node-agent-r2w7h                      1/1     Running   0          30s
weka-operator-node-agent-v7qnd                      1/1     Running   0          30s
```

You should see 1 controller pod + `n` node pods (where `n` equals number of OpenShift nodes)

2. Create wekaPolicy objects:

```
oc create -f wekapolicy.yaml
```
The wekaPolicy objects sign available hard drives and use them to build a wekaCluster. 
However, today, it errors out. This is because of insufficient permissions.

Today, you can confirm this by observing the logs of the controller pod after wekaPolicies are created.

```
22:59:09 ERR WekaContainerReconcile > Error processing reconciliation steps error="error reconciling object WekaContainer:weka-operator-system:weka-sign-and-discover-drives-ip-10-0-30-6.us-east-2.compute.internal during phase ensurePod-fm: Failed to create pod: pods \"weka-sign-and-discover-drives-ip-10-0-30-6.us-east-2.compute.internal\" is forbidden: unable to validate against any security context constraint: [provider \"anyuid\": Forbidden: not usable by user or serviceaccount, provider restricted-v2: .spec.securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used, spec.volumes[1]: Invalid value: \"hostPath\": hostPath volumes are not allowed to be used, spec.volumes[2]: Invalid value: \"hostPath\": hostPath volumes are not allowed to be used, spec.volumes[3]: Invalid value: \"hostPath\": hostPath volumes are not allowed to be used, spec.volumes[4]: Invalid value: \"hostPath\": hostPath volumes are not allowed to be used, provider restricted-v2: .containers[0].privileged: Invalid value: true: Privileged containers are not allowed, provider restricted-v2: .containers[0].hostPID: Invalid value: true: Host PID is not allowed to be used, provider \"restricted-v3\": Forbidden: not usable by user or serviceaccount, provider \"restricted\": Forbidden: not usable by user or serviceaccount, provider \"nested-container\": Forbidden: not usable by user or serviceaccount, provider \"nonroot-v2\": Forbidden: not usable by user or serviceaccount, provider \"nonroot\": Forbidden: not usable by user or serviceaccount, provider \"hostmount-anyuid\": Forbidden: not usable by user or serviceaccount, provider \"hostmount-anyuid-v2\": Forbidden: not usable by user or serviceaccount, provider \"machine-api-termination-handler\": Forbidden: not usable by user or serviceaccount, provider \"hostnetwork-v2\": Forbidden: not usable by user or serviceaccount, provider \"hostnetwork\": Forbidden: not usable by user or serviceaccount, provider \"hostaccess\": Forbidden: not usable by user or serviceaccount, provider \"insights-runtime-extractor-scc\": Forbidden: not usable by user or serviceaccount, provider weka-operator-controller-manager-scc: .spec.securityContext.hostPID: Invalid value: true: Host PID is not allowed to be used, provider weka-operator-controller-manager-scc: .containers[0].hostPID: Invalid value: true: Host PID is not allowed to be used, provider \"csi-wekafs-controller-scc\": Forbidden: not usable by user or serviceaccount, provider \"csi-wekafs-node-scc\": Forbidden: not usable by user or serviceaccount, provider \"node-exporter\": Forbidden: not usable by user or serviceaccount, provider \"weka-operator-maintenance-scc\": Forbidden: not usable by user or serviceaccount, provider \"privileged\": Forbidden: not usable by user or serviceaccount]" container_name=weka-sign-and-discover-drives-ip-10-0-30-6.us-east-2.compute.internal deployment_identifier=231b9f2f-f134-4b00-ae5c-6fc7a1b4f5df namespace=weka-operator-system
```
In order to fix this, assign the `privileged` SCC to the `default` ServiceAccount in the `weka-operator-system` Project:
```
✗ oc adm policy add-scc-to-user privileged -z
weka-operator-controller-manager

clusterrole.rbac.authorization.k8s.io/system:openshift:scc:privileged added: "weka-operator-controller-manager"
```
Now, try deleting and re-creating the wekaPolicy. Confirm the wekaPolicy worked as expected:

```
oc describe node | grep weka.io/
```
Each node should have the following annotations added to them after a successful wekaPolicy execution:
- `weka.io/weka-drives`
- `weka.io/sign-drives-hash`
- `weka.io/discovery.json`

You can confirm this by executing the following command, which returns all nodes which have the `weka.io/weka-drives` annotation applied:
```
oc get nodes -o json | jq -r '.items[] | select(.metadata.annotations."weka.io/weka-drives") | .metadata.name'

ip-10-0-12-29.us-east-2.compute.internal
ip-10-0-30-6.us-east-2.compute.internal
ip-10-0-39-13.us-east-2.compute.internal
ip-10-0-49-167.us-east-2.compute.internal
ip-10-0-52-68.us-east-2.compute.internal
ip-10-0-56-107.us-east-2.compute.internal
```

You can also check the output of `oc get wekaPolicy --all-namespaces`

3. Create a wekaCluster object:
```
oc create -f wekacluster.yaml
```
Observe the progression of cluster deployment with:
```
watch oc get pods,wekacluster -n weka-operator-system
```
wekaCluster should progress through the following stages: `Init`, `ReadyForIO`, `StartingIO`, and `Ready`

The wekaCluster is installed and ready when it reports the `Ready` status.

```
oc get wekacluster
NAME          STATUS   CLUSTER ID                             CCT(A/C/D)   DCT(A/C/D)   DRVS(A/C/D)
cluster-dev   Ready    99ac745a-ecf9-4a67-85ce-80b9a7132442   6/6/6        6/6/6        6/6/6
```

4. Create a wekaClient and access storage from the wekaCluster
