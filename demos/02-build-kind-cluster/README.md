# How to build a KinD Cluster

## Introduction

The following article builds a KinD cluster for use with the following demos.

## Prerequisites

- Followed [kube-shell](https://github.com/amcginlay/kube-shell) or have access to the client-side tools

# Steps

Provide a name for your cluster
```
k8s_cluster_name=<CLUSTER_NAME> # optional, will default to "kind"
```

Create new KinD cluster with a **single worker node** as follows.
```
k8s_cluster_name=${k8s_cluster_name:-kind}
cat <<EOF | envsubst | kind create cluster --config -
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: ${k8s_cluster_name}
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
