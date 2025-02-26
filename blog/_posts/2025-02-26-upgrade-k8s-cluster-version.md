---
layout: post
title: Upgrading my Kubernetes cluster
sitemap: false
hide_last_modified: true
---

Part of the responsibility of being a DevOps engineer comes with keeping software, other dependencies, and platforms/systems up-to-date. One of these is Kubernetes. Staying up-to-date with the latest version of Kubernetes is very important. In addition to bug fixes and new features, there is also the occasional security fix/update. Security is crucial in a platform as large as Kubernetes.

Kubernetes versions change very often (about every 4 months), so it's important to keep your cluster up-to-date. Before getting started, you want to read, or at least skim the release notes for each version since your current version. I know it's kind of a hassle, but it's important to know what's being updated. The following are some things you'll find in updates:

1. Security fixes/updates
2. Bug fixes
3. New features
4. Breaking changes or other upgrade notes that you must be aware of prior to upgrading


## Upgrade process (control plane node)

For my cluster, I used the instructions from this [link](https://v1-31.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/) (but the current documentation can be found [here](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/). I basically followed these instructions. But I will lay out all the steps I made in this post.

You can see what version your cluster is currently running by executing the command `kubectl get nodes`.

My upgrade process is as follows:

1. Upgrade current MINOR version: 1.30.2 --> 1.30.10
2. Upgrade from 1.30.10 --> 1.31.6

Since my CNI addon has not been tested with version 1.32.x of Kubernetes, we'll stop here and stay on 1.31.x for now.


### Update the package repository

First, we've got to download and install the newest public signing key for the Kubernetes package repository[^1].

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```


### Find which version of package to upgrade to

```bash
# Find the latest 1.30 version in the list.
# It should look like 1.30.x-*, where x is the latest patch.
sudo apt update
sudo apt-cache madison kubeadm
```


### Upgrade control plane node

1. Upgrade kubeadm:

   ```bash
   sudo apt-mark unhold kubeadm && \
   sudo apt-get update && sudo apt-get install -y kubeadm='1.30.10-1.1' && \
   sudo apt-mark hold kubeadm
   ```

2. Verify the expected version was installed:

   ```bash
   kubeadm version
   ```

3. Verify the upgrade plan:

   ```bash
   sudo kubeadm upgrade plan
   ```

4. Choose the version to upgrade to and run the upgrade:

   ```bash
   sudo kubeadm upgrade apply v1.30.10
   ```

5. Manually upgrade my CNI provider plugin.

   I'm using Canal (Calico for policy and Flannel for networking). I will therefore follow their instructions for upgrading Canal[^2].

    1. Fetch the K8s manifest:
       ```bash
       curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/canal.yaml -o upgrade.yaml
       ```

    2. Initiate a rolling update:
       ```bash
       kubectl apply --server-side --force-conflicts -f upgrade.yaml
       ```

    3. We can watch as this update occurs.
       ```bash
       watch kubectl get pods -n kube-system
       ```


### Drain the node

   ```bash
   kubectl drain k8s-master --ignore-daemonsets
   ```


### Upgrade kubelet and kubectl

1. Upgrade the kubelet and kubectl:

   ```bash
   sudo apt-mark unhold kubelet kubectl && \
   sudo apt-get update && sudo apt-get install -y kubelet='1.30.10-1.1' kubectl='1.30.10-1.1' && \
   sudo apt-mark hold kubelet kubectl
   ```

2. Restart the kubelet:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet
   ```


### Uncordon the node

Bring the node back online by marking it schedulable:

```bash
kubectl uncordon k8s-master
```


## Upgrade process (worker nodes)

We'll essentially repeat the same steps, but for the worker nodes this time.


### Update the package repository

First, we've got to download and install the newest public signing key for the Kubernetes package repository.

```bash
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.32/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```


### Upgrade worker nodes

1. Upgrade kubeadm:

   ```bash
   sudo apt-mark unhold kubeadm && \
   sudo apt-get update && sudo apt-get install -y kubeadm='1.30.10-1.1' && \
   sudo apt-mark hold kubeadm
   ```

2. Upgrade the node by calling "kubeadm upgrade":

   ```bash
   sudo kubeadm upgrade node
   ```


### Drain the node

   ```bash
   # execute this command on a control plane node
   kubectl drain k8s-node1 --ignore-daemonsets
   ```


### Upgrade kubelet and kubectl

1. Upgrade the kubelet and kubectl:

   ```bash
   sudo apt-mark unhold kubelet kubectl && \
   sudo apt-get update && sudo apt-get install -y kubelet='1.30.10-1.1' kubectl='1.30.10-1.1' && \
   sudo apt-mark hold kubelet kubectl
   ```

2. Restart the kubelet:

   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart kubelet
   ```


### Uncordon the node

Bring the node back online by marking it schedulable:

```bash
# execute this command on a control plane node
kubectl uncordon k8s-node1
```


## Next steps

We'll repeat this process for the remaining node(s). In my case, `k8s-node2`.

Next is to upgrade from version 1.30.10 to version 1.31.6. We'll follow the same steps as we previously did, but first we'll run this extra step on each node.


## Update the package repository

We've got to add the apt repository so the packages can be upgraded. Kubernetes has individual repositories for each minor release of Kubernetes, rather than a single repository for all versions[^1]. This needs to be run on each node, both the control plane and the two worker nodes.

```bash
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
```


[^1]: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#k8s-install-0
[^2]: https://docs.tigera.io/calico/latest/operations/upgrading/kubernetes-upgrade#upgrading-an-installation-that-uses-manifests-and-the-kubernetes-api-datastore
