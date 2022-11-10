# Build KinD Cluster

## Introduction

The following article builds a KinD cluster for use with the following demos.

## Prerequisites

- Completed [Start kube-shell](../README.md)

# Steps

Provide a name for your cluster
```
export cluster_name=<enter-cluster-name-here>
```

Create new KinD cluster with a **single worker node** as follows.
```
cat <<EOF | envsubst | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${cluster_name}
nodes:
- role: control-plane
- role: worker
EOF
```

**NOTE** worker nodes are optional. The number of worker nodes is defined by the number of times the line `- role: worker` appears in your config file.

View your KinD clusters and check connectivity as follows.
```
kind get clusters
kubectl config get-clusters
kubectl config current-context
kubectl cluster-info
```

This chapter is complete.

Next: [Main Menu](/README.md) | [03. EKS with ingress-nginx and cert-manager](../03-eks-ingress-nginx-cert-manager/README.md)
