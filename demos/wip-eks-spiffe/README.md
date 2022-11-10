# EKS/SPIFFE demo

## Introduction
Traditional TLS ensures that clients interact only with trusted servers.
[mTLS](https://en.wikipedia.org/wiki/Mutual_authentication#mTLS) extends this notion into a bi-directional arrangement whereby the server also ensures that inbound traffic arrives from only known/trusted clients.
This is the basis of "zero-trust" security, the likes of which one might encounter within B2B applications.
The aim of this demo is to observe mTLS in action, leveraging microservices deployed on EKS App Mesh with SPIFFE/SPIRE acting as both the trust registry and short-term (~1hr) X.509 certificate broker.
It's worth noting that it is the SPIRE agents' responsibility to push renewed certificates out to Envoy proxies which negates the need for workload restarts when new certificates are issued.
There is no requirement for **cert-manager** in this demo

This demo draws from [this](https://aws.amazon.com/blogs/containers/using-mtls-with-spiffe-spire-in-app-mesh-on-eks/) AWS blog article.
It assumes that a Linux or MacOS client with the latest versions of **aws**, **eksctl**, **kubectl** and **helm** tools provisioned and appropriately configured for an AWS account.

## EKS setup
To complete this exercise you will need an appropriately configured EKS cluster.
If you need help getting a cluster up and running, please refer to [these instructions](https://github.com/amcginlay/eks-demos).
Of particular importance for this exercise is the managed node group policies which are set via the `eksctl` cluster config.
The cluster config file should include something like the following:
```bash
...
managedNodeGroups:
- name: whatever
  iam:
    withAddonPolicies:
      certManager: true
      cloudWatch: true
      appMesh: true
...
```

Note the above manifest created the `appmesh-system` namespace and an appropriately configured service account named `appmesh-controller`.

Now add the App Mesh Service Account, Controller and CRDs. This operation will also create the `appmesh-system` namespace.
```bash
region=<INSERT_REGION_HERE>
cluster=<INSERT_CLUSTER_NAME_HERE>

eksctl create iamserviceaccount \
  --cluster ${cluster} \
  --namespace appmesh-system \
  --name appmesh-controller \
  --attach-policy-arn arn:aws:iam::aws:policy/AWSCloudMapFullAccess,arn:aws:iam::aws:policy/AWSAppMeshFullAccess \
  --override-existing-serviceaccounts \
  --approve

helm repo add eks https://aws.github.io/eks-charts
helm upgrade -i appmesh-controller eks/appmesh-controller \
               --namespace appmesh-system \
               --set region=${region} \
               --set serviceAccount.create=false \
               --set serviceAccount.name=appmesh-controller \
               --set sds.enabled=true
```

The important point to note from the controller installation is the inclusion of the `sds.enabled=true` setting which enables use of the [Envoy Secret Discovery Service](https://www.envoyproxy.io/docs/envoy/latest/configuration/security/secret).

You can observe the newly available CRDs as follows.
```bash
kubectl api-resources --api-group=appmesh.k8s.aws -o wide
```

Configure an instance of **nginx** to act as a "jumpbox" and test the welcome page.
```bash
kubectl run jumpbox --image=nginx
sleep 10 && kubectl exec -it jumpbox -- curl http://localhost:80
```

## SPIFFE/SPIRE setup
Clone the source repo, which you will draw from in this section.
```bash
mkdir -p ~/environment && cd $_ # aligns with Cloud9 default behaviour
git clone https://github.com/aws/aws-app-mesh-examples.git
```

The topics covered in the cloned repo are wide ranging but your focus will be solely on `/walkthroughs/howto-k8s-mtls-sds-based`.

Next, install the SPIFFE/SPIRE server (statefulset) and agents (daemonset).
This introduces the `howto-k8s-mtls-sds-based.aws` trust domain which your workloads will belong to.
```bash
src=~/environment/aws-app-mesh-examples/walkthroughs/howto-k8s-mtls-sds-based
kubectl apply -f ${src}/spire/spire_setup.yaml
```

You can observe the newly created SPIFFE/SPIRE resources as follows.
```bash
kubectl -n spire get all -o wide
```

## SPIFFE/SPIRE workload registrations
To configure mTLS between the workloads (not yet deployed!) you first need to register the workloads you wish to include plus the agent(s).
So the following workloads will now be registered.
- the **front** app
- the **blue color** backend app
- the **red color** backend app
- the **spire agent(s)**
```bash
${src}/spire/register_server_entries.sh register
```

You can query the registered entries by probing the server as follows.
As you do, take a moment to observe the heirarchical nature of `SPIFFE ID` and `Parent ID` properties.
```bash
kubectl exec -n spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show
```

You will note that the **green color** backend app is *not* registered with SPIFFE/SPIRE, which is intentional at this point.

## App deployment and service mesh configuration
Before you deploy **the app** and all **its App Mesh resources**, take a moment to observe the manifest template and the associated script which form the basis of this deployment.
```bash
cat ${src}/v1beta2/manifest.yaml.template
cat ${src}/deploy_app.sh
```

Some things to note from these resources are as follows:
- The VirtualNode for **front** uses a carefully chosen set of options in the `backendDefault.clientPolicy` section to enforce **mTLS**
- The namespace indicates its participation in the mesh by means of a k8s label `mesh`
- The template is littered with variables (e.g. APP_NAMESPACE, MESH_NAME) which will be resolved at runtime by the `deploy_app.sh` script.

Now we can deploy the app as follows.
```bash
ENVOY_IMAGE=n/a ${src}/deploy_app.sh
```

The `${src}/deploy_app.sh` script performs the following tasks:
- builds Docker images from code in `${src}/colorapp` and `${src}/feapp` directories
- pushes images from Docker to ECR repos in current AWS account
- uses `eval` to resolve variables in the `manifest.yaml.template` document, transcribing a `${src}/_output/manifest.yaml` for deployment
- creates k8s resources of the following kinds: `Namespace`, `Mesh`, `VirtualNode`, `VirtualService`, `VirtualRouter`, `Service`, `Deployment`

Take a moment to navigate around the AWS App Mesh resources which are visible [here](https://console.aws.amazon.com/appmesh/meshes), adjusting the region as necessary.

Despite the **green color** backend app remaining **unregistered** with SPIFFE/SPIRE, you will note that the app is now **deployed**.

## Testing
At this point **HTTP** access from the "jumpbox" to `front` is accepted and it can successfully route/forward traffic to `color-blue` and `color-red` as follows.
```bash
kubectl exec -it jumpbox -- curl -H "color_header: blue" http://front.howto-k8s-mtls-sds-based.svc.cluster.local:8080; echo;

kubectl exec -it jumpbox -- curl -H "color_header: red" http://front.howto-k8s-mtls-sds-based.svc.cluster.local:8080; echo;
```

Yet any attempt to route traffic to `color-green` fails with a "503 Service Unavailable" as you can observe here.
```bash
kubectl exec -it jumpbox -- curl -H "color_header: green" http://front.howto-k8s-mtls-sds-based.svc.cluster.local:8080; echo;
```

The `color-green` route failed because, despite the App Mesh components knowing about the existence of the the path, it had not *yet* been approved for use with SPIFFE/SPIRE.
Resolve this as follows, then re-attempt the failed route.
```bash
${src}/spire/register_server_entries.sh registerGreen

kubectl exec -it jumpbox -- curl -H "color_header: green" http://front.howto-k8s-mtls-sds-based.svc.cluster.local:8080; echo;
```

So `front` can now access all the `color` workloads, but how about accessing these directly?
Observe what happens if you attempt **HTTPS** access to `color-blue` in the same way.
As your mesh now represents a zero-trust achitecture HTTP is no longer supported.
The `-k` flag on the following curl request instructs curl to accept the use of self-signed certificates, such as those published by SPIFFE/SPIRE.
```bash
kubectl exec -it jumpbox -- curl -k https://color-blue.howto-k8s-mtls-sds-based.svc.cluster.local:8080; echo;
```

This fails with a `alert certificate required` error since mTLS is now strictly enforced between the `color` "servers" and any "client" wishing to communicate with them.
Your "jumpbox", being deployed in the `default` namespace, is neither App Mesh configured nor does it has access to the certificate which all `color-blue` clients require.
You may add `-v` to the `curl` request to see more detailed failure info.

TODO we might want to extend this to querying the envoy logs
TODO run through the [README](https://github.com/aws/aws-app-mesh-examples/blob/main/walkthroughs/howto-k8s-mtls-sds-based/README.md)
