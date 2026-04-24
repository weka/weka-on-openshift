# WEKA on OpenShift

[WEKA](https://www.weka.io/) is a high-performance filesystem that is fully containerized. Deploy and maintain storage clusters using the [WEKA Operator](https://docs.weka.io/kubernetes/composable-clusters-for-multi-tenancy-in-kubernetes). 

[OpenShift](https://www.redhat.com/en/technologies/cloud-computing/openshift) is an enterprise-grade container orchestrator, built and maintained by Red Hat.

This repo explains how WEKA clusters can be deployed on OpenShift environments.

WEKA clusters can also be deployed external to OpenShift environments. In such instances, ONLY a WEKA Client must be deployed on OpenShift. Here, one creates a [wekaClient](https://docs.weka.io/kubernetes/weka-operator-deployments#id-3.-install-the-wekaclient-cr), with `joinIpPorts` defined.

## How to use this repo

For specific instructions, click the links below:

[Deploying OpenShift](deploy-ocp/README.md).

[Installing WEKA on OpenShift](install-weka-on-ocp/README.md).

[Configuring access to external WEKA storage for OpenShift](external-weka-to-ocp/README.md).

[Best Practices](best-practices/README.md).

## Prerequisites

- A working OpenShift cluster. A non-Hosted Control Plane cluster is required.
  - 6 nodes recommended (3 control plane + 3 worker nodes).
  - Minimum 12 vCPUs per node (16 recommended).
- Access to host ports 14000 - 40000. If using a cloud service provider like AWS, add rules in appropriate Security Groups.

## Supported OpenShift versions and deployments
Versions `4.17` and above are known to work with WEKA.

Self-managed OpenShift installs are known to work with WEKA. Bare-metal deployments and user provisioned infrastructure on clouds fall in this category.

Fully-managed OpenShift installs (ROSA, ARO, OpenShift on IBM Cloud, OpenShift Dedicated) are NOT known to work. This is due to lack of master node access.

>[!WARNING]
> Hosted Control Plane clusters do not work, on account of certain required CRDs not being exposed (such as `MachineConfig`), making it hard to update HugePagesConfig.

## Supported host operating systems

Ubuntu and CoreOS.
OpenShift uses CoreOS by default.

## Supported WEKA versions
Versions `v1.9.0` and later are known to work with OpenShift.

It is **always** recommended to use the most recent available version of the WEKA Operator. Releases are published here: <https://get.weka.io/ui/operator>.
