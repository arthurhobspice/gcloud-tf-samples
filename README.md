# General

The files in this repository demonstrate resource creation on Google Cloud (GCP) using Terraform:
a Compute Instance or a GKE cluster.They are only for getting started and showing the basic ideas and use
a personal GCP project.

# Google Cloud SDK

Install Google Cloud SDK (Linux): download tar.gz, unpack, run install.sh -> among others, tools are added to PATH.
The main command line tool is gcloud.

On Windows: download and run GoogleCloudSDKInstaller.exe.

Execute gcloud init, answer questions. You will be forwarded to the Google web page and have to confirm that Google Cloud
SDK is authorised to access the project. After that configure default region and zone.

Example of a gcloud command:
```
gcloud compute instances list
```

works fine.

gcloud init creates a directory .config/gcloud, with file configurations/config_default:

```
[core]
account = <email>
project = <project>

[compute]
zone = europe-west3-a
region = europe-west3
```

(Frankfurt is europe-west3.)

See https://cloud.google.com/sdk/docs/configurations.

On Windows: configuration is in %USERPROFILE%\AppData\Roaming\gcloud.

gcloud uses Python, the Windows installation contains a bundled Python. If other software packages install a
Python, too, you may get "Permission denied" errors. Instruct gcloud to use bundled Python (Git bash):

```
export CLOUDSDK_PYTHON="/c/Users/chris/AppData/Local/Google/Cloud SDK/google-cloud-sdk/platform/bundledpython/python"
```

# Terraform

https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started
https://cloud.google.com/community/tutorials/getting-started-on-gcp-with-terraform

Create and store credentials for a GCP project:

```
gcloud auth application-default login
```

Opens a browser where you can perform the login. A file .config/gcloud/application_default_credentials.json in
the home directory is created. That's already enough to run terraform commands.

Google recommends to use a service account in Terraform. We already have one, open the 
key management, create a new key (JSON) -> download JSON file -> store in ~/.config/gcloud/myprojectfile.json. 
Then run

```
export GOOGLE_APPLICATION_CREDENTIALS=~/.config/gcloud/myprojectfile.json
```

or add the file path and name to provider.tf ("credentials").

Creation of a Compute Engine instance:
- "network" or "subnetwork" has to be defined. I.e. first you have to create a VPC (or use "default").
- auto_create_subnetworks = "true" will create subnets in all regions automatically, spread over the 10.128.0.0/9 range.
  With "false" you have to create google_compute_subnetwork resources explicitly.
- The "default" network has a set of standard firewall rules, e.g. for ssh. For new networks you have to define
  firewall rules yourself.

"Labels" correspond to "tags" in AWS. Labels have restrictions: keys and values may only contain lower-case
letters, numbers, underscores and dashes.

# Google Kubernetes Engine

## GKE with Terraform

Example and tutorial: https://learn.hashicorp.com/tutorials/terraform/gke

In local clone of this repository gcloud_tf_samples, go to gke directory, run terraform apply.

Cluster and services CIDR blocks cannot be part of a VPC network for Compute Engines.

Creation of the cluster: approx. 9 minutes

Last step NodePool requires an increased quota IN_USE_ADDRESSES, 8 are not enough -> request increase via
Google Service Request, will be answered on short notice.

Creation of node pool: error after 25 minutes (0 nodes). With some machine types you run into error
"not enough resources". Choose another machine type -> "Error waiting for creating GKE NodePool: All cluster resources
were brought up, but: only 0 nodes out of 3 have registered; cluster may be unhealthy."

If the node pool remains in this faulty, half-ready state, terraform will assume that
it does not exist yet. Next run will then fail with "alreadyExists" error.
Delete it manually via the Console.

Without any machine_type definition the node pool is successfully created in 1:20 min.
machine_type has been set to e2-medium automatically.

**node_count is a number of nodes per zone, hence total number is three times higher!**

Change number in variables.tf, run terraform apply -> cluster in state "Repairing the cluster"
in GKE Console for a long time, then "Resizing the node pool". Terraform returns only after more than 15 min.

Define autoscaling and set labels -> both require deletion and recreation of node pool.
In sum ~ 6 minutes. **An already deployed Kubernetes dashboard (see below) is still available after this change!**
A modification of autoscaling parameters (min, max) takes a few seconds.
**min_node_count and max_node_count are numbers per single zone, too!**

## Accessing the cluster

Install kubectl:

```
sudo apt-get update && sudo apt-get install -y apt-transport-https
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl
```

Alternatively you can install kubectl with "gcloud components install kubectl", esp. on Windows.

Create cluster credentials:

```
gcloud container clusters get-credentials tf-sample-gke --region europe-west3
kubectl cluster-info
```

## Kubernetes dashboard

kubernetes-dashboard.yml is the file https://raw.githubusercontent.com/kubernetes/dashboard/v2.0.0/aio/deploy/recommended.yaml,
downloaded with curl or wget.

```
kubectl apply -f kubernetes-dashboard.yml
```

Inspect the deployment and set up connection to dashboard:

```
kubectl get pods -n kubernetes-dashboard
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8080:443
```

then open https://localhost:8080 in Browser.

Or expose the dashboard using a LoadBalancer type service, but that is open to the Internet:

```
kubectl expose deployment -n kubernetes-dashboard --name=kubernetes-dashboard-pub --type=LoadBalancer --port 443 --target-port 8443
kubectl get service -n kubernetes-dashboard
```

Open issue: kubectl proxy does not work: after

```
kubectl proxy
```

opening this URL

http://127.0.0.1:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/

in a browser runs on timeout ("Error trying to reach service: 'dial tcp 10.11.6.6:8443: i/o timeout'").
10.11.6.6 is from the "cluster-ipv4-cidr-block" (ClusterIP). Do we need further firewall rules?

Create service account and ClusterRoleBinding and log in to dashboard:

```
kubectl apply -f serviceaccount.yml
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes-dashboard get sa/admin-user -o jsonpath="{.secrets[0].name}") -o go-template="{{.data.token | base64decode}}"
```

Enter the token into the login mask.

Set namespace context, so that you don't need to enter namespace explicitly all the time:

```
kubectl config set-context --current --namespace=kubernetes-dashboard
```

## Deployment of nginx with ingress controller

https://cloud.google.com/kubernetes-engine/docs/concepts/ingress

Expose via load balancer vs. ingress:
https://medium.com/google-cloud/kubernetes-nodeport-vs-loadbalancer-vs-ingress-when-should-i-use-what-922f010849e0

Deployment of nginx:

```
kubectl create namespace nginx
kubectl config set-context --current --namespace=nginx
kubectl apply -f nginx.yml
```

Create a self-signed certificate for the ingress controller and store as Kubernetes secret:

```
openssl req -newkey rsa:2048 -x509 -sha256 -days 3650 -nodes -out nginx.crt -keyout nginx.key
kubectl create secret tls tls-nginx --key="nginx.key" --cert="nginx.crt"
kubectl get secret
```

Use the certificate and key to create the ingress controller:

```
kubectl apply -f ingress.yml 
```

Open the public IP address in a browser.

## Start a diagnostic pod providing in-cluster curl

```
kubectl run curl-test --image=radial/busyboxplus:curl -i --tty --rm
```

## Persistent Volume

The Terraform code creates a Regional Disk tf-sample-gke-disk. Create volume and volume claim with kubectl:

```
kubectl create namespace pv-demo
kubectl apply -f volumeclaim.yml
kubectl get persistentvolume pv-demo
kubectl get persistentvolumeclaim pv-claim-demo -n pv-demo
kubectl describe persistentvolume
kubectl describe persistentvolumeclaim -n pv-demo
```

It is possible (and recommended) to create Regional Disks for persistent volumes and volume claims dynamically.
See https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/regional-pd?hl=de#dynamic-provisioning.

