#!/bin/bash

##This script creates an OpenShift cluster with ARM instances for you##
##Best used on a free AWS Graviton bastion host or on a mac with ARM chip###

#Adjust these variables
# set aws access variables
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_SESSION_TOKEN=""
export OCP_VERSION=4.19.27
# wipe screen.
clear

echo "#.#.#.#.Begin run to deploy an OpenShift cluster of version ${OCP_VERSION} on ARM instances.#.#.#.#"
echo "...\n...\n"

echo "Dowloading and extracting Openshift installer version ${OCP_VERSION}..."
command wget -nc https://mirror.openshift.com/pub/openshift-v4/aarch64/clients/ocp/${OCP_VERSION}/openshift-install-mac.tar.gz
command tar xzvf openshift-install-mac.tar.gz openshift-install
command chmod u+x openshift-install
command cp openshift-install ~/bin/

echo "Downloading oc client version ${OCP_VERSION}.."
command wget -nc https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/${OCP_VERSION}/openshift-client-mac.tar.gz
command tar xzvf openshift-client-mac.tar.gz oc
command chmod u+x oc
command cp oc ~/bin/

echo "Deploying an openshift cluster with openshift-install..."
command openshift-install create cluster --dir=. --log-level=debug > install.log 2>&1 &

echo "Sleep for 150...tail install.log if you want..."
command sleep 150s

echo "Monitoring progress of install with openshift-install wait-for install-complete command..."
command openshift-install wait-for install-complete
