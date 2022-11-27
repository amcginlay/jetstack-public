# How to build a KinD Cluster

## Introduction

The following article builds a KinD cluster for use with the following demos.

## Prerequisites

- Followed [kube-shell](https://github.com/amcginlay/kube-shell) or otherwise have access to the common command line tools

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
    kubeadmConfigPatches:
      - |
        kind: InitConfiguration
        nodeRegistration:
          kubeletExtraArgs:
            node-labels: "ingress-ready=true"        
    extraPortMappings:
      - containerPort: 80
        hostPort: 80
        protocol: TCP
      - containerPort: 443
        hostPort: 443
        protocol: TCP
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
kubectl get nodes -owide
```

### A note on LoadBalancer services

KinD does not provide native support for Kubernetes services of type LoadBalancer.
Tools like MetalLB (described [here](https://kind.sigs.k8s.io/docs/user/loadbalancer/)) promise to solve this problem but, due to differences in the Docker network configuration, only really work on Linux machines.

If you're using Docker for Desktop on MacOS or Windows the prefered/cleanest way to route traffic from your Laptop to your workloads running in KinD is to either:

- set up an Ingress Controller (e.g. ingress-nginx) as described [here](https://kind.sigs.k8s.io/docs/user/ingress/)
- make use of the `kubectl port-forward` feature.

<!-- switch images from hashicorp/http-echo:0.2.3 to larstobi/http-echo:0.2.4 to avoid aarch64 compatibility issues -->

This chapter is complete.

Next: [Main Menu](/README.md) | [03. EKS with ingress-nginx and cert-manager](../03-eks-ingress-nginx-cert-manager/README.md)
