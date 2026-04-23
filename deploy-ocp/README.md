# Deploying an OpenShift cluster

This README walks you through the steps involved to deploy an OpenShift cluster.

Clone this repo on an Amazon Linux `arm64` instance to use `deploy-ocp.sh`.

This script uses `install-config.yaml` to provide config parameters.

## Steps to deploy an OpenShift cluster

1. **Create a Red Hat account**. Visit console.redhat.com and follow the instructions to create a user account.

2. **Log in to console.redhat.com** and create a cluster.

![Openshift-cluster-create](https://github.com/user-attachments/assets/14c77bba-640c-4731-a56f-ef18fb67723d)

3. If provisioning infrastrucure, download `openshift installer` and generate `install-config.yaml`.

![Generate-install-config](https://github.com/user-attachments/assets/60cc3cb4-8c03-4f2e-ba6a-bf25cf6ade1b)

4. Create cluster by using `openshift-install create cluster`.

![Openshift-install-cluster-create](https://github.com/user-attachments/assets/982ad92d-4e96-4609-b858-958a9f037049)

5. Once the cluster is created (takes 40 minutes or so), you can access the cluster.

![access-openshift-cluster](https://github.com/user-attachments/assets/83d84023-49ec-42da-aa33-7ca4548e3040)
