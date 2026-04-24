# Best Practices

Listed below are some best practices to be mindful of when working with WEKA and OpenShift.

## Generally Applicable

- ALWAYS set `network.udpMode=True` in your `wekaClient` and `wekaCluster` definition. Currently, WEKA is not qualified to use DPDK with OpenShift. This effort requires `SR-IOV` support in WEKA.
- If workloads utilizing CPU cores exist in your OpenShift cluster, it is RECOMMENDED to set `cpuPolicy=Auto` in your `wekaClient` definition. This helps ensure workloads do not compete to utilize the same CPU cores.
- If your OpenShift cluster is NOT air-gapped, set `spec.driversDistService="https://drivers.weka.io"` in your `wekaClient` and `wekaCluster` definitions. Required driver container images are retrieved from a public Internet endpoint, instead of being built locally.

## Air-Gapped Installations

- WEKA allows storage drivers to be built locally. To achieve this, you must:
  - Create a `wekaPolicy` of `spec.type=enable-local-drivers-distribution`. An example is provided in this directory, named [distribute-drivers-wekapolicy](distribute-drivers-wekapolicy.yaml).
  - This creates a Kubernetes Service in your desired namespace, which you will then reference in your `wekaCluster` definition. An example is provided in this directory, named [wekacluster-local-drivers.yaml](wekacluster-local-drivers.yaml).
  - In this manner, WEKA operator is restricted from retrieving driver container images from the public internet. Instead, they are built locally in your OpenShift cluster.
- To access storage from your WEKA cluster on OpenShift, create a wekaClient as shown in [wekaclient-local-drivers.yaml](wekaclient-local-drivers.yaml). By setting `spec.driversDistService` to a local Kubernetes service, container images are not retrieved from the public internet.
