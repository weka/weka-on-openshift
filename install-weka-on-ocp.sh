#!/bin/bash
#Adjust these variables
# set aws access variables
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_SESSION_TOKEN=""
export OCP_VERSION=4.19.27
export WEKA_OPERATOR_VERSION=v1.10.5
export WEKA_VERSION=4.4.10.202

# wipe screen.
clear

echo "#.#.#.#.Begin run to install WEKA version ${WEKA_VERSION}.#.#.#.#"
echo "...\n...\n"

echo "..Configuring Master nodes to make them scheduleable..\n"
command oc patch schedulers.config.openshift.io cluster --type='json' -p='[{"op": "replace", "path": "/spec/mastersSchedulable", "value":true}]'

echo "..Configuring Huge Pages on all nodes..\n"
command oc create -f worker-hpc.yaml
command oc create -f master-hpc.yaml

echo "..Takes some time to apply..Continuing with install.\n"

echo "..Sleep for 10s..\n"
sleep 10s

# Check the helm installation.
echo "\n\nChecking if Helm is installed...\n\n"
command -v helm version --short >/dev/null 2>&1 || { echo >&2 "Helm version 3+ is required but not installed yet... download and install here: https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3"; exit; }
echo "\n\nHelm good to go!...\n\n"

# Check the kubectl installation.
echo "\n\nChecking if kubectl is installed...\n\n"
command -v kubectl version >/dev/null 2>&1 || { echo >&2 "Kubectl is required but not installed yet... download and install: https://kubernetes.io/docs/tasks/tools/"; exit; }
echo "\n\nkubectl good to go!...\n\n"

## Access k8s cluster.
echo "\n\nStatus of nodes in the cluster....\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes

if [ $? -ne 0 ]; then
  echo
	echo "\n\nError occurred during kubectl get nodes???.Is your KUBECONFIG variable set??\n\n"
	echo
	exit;
fi

echo "\n\nExamining huge pages config on each node..\n\n"
echo "Guidelines: https://docs.weka.io/kubernetes/weka-operator-deployments#configure-hugepages-for-kubernetes-worker-nodes\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o custom-columns='NAME:.metadata.name,HUGEPAGES-2Mi:.status.allocatable.hugepages-2Mi,HUGEPAGES-1Gi:.status.allocatable.hugepages-1Gi'

echo "\n\nDoes this look okay?..Sleeping for 10 seconds..\n\n\n"

sleep 10s

echo "\n\nCreating WEKA Operator namespace and WEKA secret...\n\n"

command oc create ns weka-operator-system
command oc create -f secret.yaml

echo "\n\nProceeding to deploy Weka operator version ${WEKA_OPERATOR_VERSION}...\n\n"

command helm upgrade --create-namespace --kubeconfig "${KUBECONFIG}" --install weka-operator oci://quay.io/weka.io/helm/weka-operator --namespace weka-operator-system --version ${WEKA_OPERATOR_VERSION:=v1.10.5} --set csi.installationEnabled=true

echo "\n\nWeka operator deployment complete...\n\n"

sleep 2s

echo "\n\nExamining status of pods in weka-operator-system namespace...Pods should be up and running...\n\n"

command kubectl wait --for=condition=Ready pod --all --timeout=200s --namespace weka-operator-system

if [ $? -ne 0 ]; then
        echo
        echo "Error accessing k8s cluster. Check your KUBECONFIG variable??"
        echo
        exit;
fi

echo "Elevate permissions of weka-controller-manager service account\n"
command oc adm policy add-scc-to-user privileged -z weka-operator-controller-manager -n weka-operator-system

echo "Create a wekaPolicy\n"
command oc create -f wekapolicy.yaml

echo "\n\nObserving progress of wekaPolicy...Condition is met if policy is in Done Status\n\n"

sleep 30s

command kubectl --kubeconfig "${KUBECONFIG}" wait --for=jsonpath='{.status.status}'=Done wekapolicy/sign-drives --timeout=200s -n weka-operator-system

sleep 30s

echo "\n\nPrint all nodes and the value of their weka.io/weka-drives annotation...\n\n\n"

command kubectl --kubeconfig "${KUBECONFIG}" get nodes -o custom-columns='NAME:.metadata.name,WEKADRIVES:.metadata.annotations.weka\.io/weka-drives'

sleep 10s
