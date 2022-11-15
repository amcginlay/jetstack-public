# How to build an EKS Cluster

## Introduction

The following article builds an Amazon EKS cluster for use with the following demos.

## Prerequisites

- Followed [kube-shell](https://github.com/amcginlay/kube-shell) or otherwise have access to the common command line tools
- Access to an AWS account and appropriate permisssions to provision an EKS cluster

# Steps

Confirm first that you have AWS connectivity as follows.
```
aws sts get-caller-identity
```

Use `aws configure` as necessary, ensuring that you set the region to `us-west-2`.

If you need to set up an EKS cluster you can do so as follows.
```
cluster_name=tls-ingress-demo-$(date +"%y%m%d")
eksctl create cluster --name=${cluster_name} --region=us-west-2 --nodes=2 --spot --node-private-networking --instance-types t3.small
```

Once your cluster is ready (~15 mins), `eksctl` will update your `kubectl` config file so you can test cluster connectivity as follows.
```
kubectl cluster-info
```

This chapter is complete.

Next: [Main Menu](/README.md) | [02. Build KinD Cluster](../02-build-kind-cluster/README.md)

# Undo Steps
Steps to delete the EKS cluster are as follows:
```
eksctl delete cluster ${cluster_name}
```

