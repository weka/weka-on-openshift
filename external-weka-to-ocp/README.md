# Configuring access to external WEKA storage for OpenShift clusters

Suppose you have a pre-existing WEKA cluster, deployed outside OpenShift.

How would you provide OpenShift workloads access to storage from this external WEKA cluster?

Simple!

Create a `wekaClient` object in OpenShift, populating the values as shown below.

```
$ cat external-wekaclient.yaml
apiVersion: weka.weka.io/v1alpha1
kind: WekaClient
metadata:
  name: external-cluster-client                  #Define this value as desired
spec:
  image: quay.io/weka.io/weka-in-container:5.1.0 #Update to appropriate image
  imagePullSecret: "quay-io-robot-secret"        #Update to appropriate secret
  driversDistService: "https://drivers.weka.io"  #Set to this value for external accessible clusters
  portRange:
    basePort: 46000
  wekaSecretRef: external-cluster                #Set to name of secret that contains cluster access credentials
  joinIpPorts: ["10.0.2.137:16101"]              #Set to IP addresses used to join a cluster outside the local environment
  network:
    udpMode: true                                #ALWAYS SET udpMode to TRUE for OpenShift
```

The wekaClient object is created
- AFTER deploying the WEKA Operator, and
- AFTER creating a Kubernetes Secret that contains the access credentials for the WEKA cluster.

```
# Install WEKA Operator
$ helm upgrade --create-namespace --kubeconfig "${KUBECONFIG}" --install weka-operator oci://quay.io/weka.io/helm/weka-operator --namespace weka-operator-system --version ${WEKA_OPERATOR_VERSION:=v1.10.5} --set csi.installationEnabled=true

# Create k8s access secret
$ cat cluster-secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: external-cluster
  namespace: weka-operator-system
type: Opaque
data:
  org: <base64-encoded-org>
  join-secret: <base64-encoded-join-secret>
  password: <base64-encoded-password>
  username: <base64-encoded-username>

$ kubectl apply -f cluster-secret.yaml

# Create wekaClient
$ kubectl create -f external-wekaclient.yaml
```
