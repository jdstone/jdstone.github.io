---
layout: post
title: Kubernetes home lab
description: >
  I set up a Kubernetes home lab using kubeadm, with three mini PCs.
sitemap: false
hide_last_modified: true
hide_description: true
---

I've finally gotten around to building a Kubernetes (K8s) cluster at home. This Kubernetes home lab would allow me to learn, fiddle with, and host container-based workloads.

Kubernetes is a wonderful open source system for orchestration of containers.  In others words, it handles the management, deployment, and organization of containerized applications.  It automates these tasks and makes these duties much easier than trying to craft your own system from scratch.  If you want to know more, there are many resources like the Wikipedia [entry](https://en.wikipedia.org/wiki/Kubernetes) for Kubernetes or the official [Kubernetes](https://kubernetes.io/) website.

I originally started out setting up K3S, which is a lightweight fully compliant distribution of Kubernetes.  But after getting it partially set up, I decided to go the full Kubernetes route and use [kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/) to build my cluster.  I had a couple of reasons for this:

  1. It would provide me with more insight and more in-depth knowledge into the intricacies of Kubernetes and how it works. Which in turn should provide a better understanding of K8s and how to troubleshoot it.
  2. This is the same (or similar, depending on configuration) Kubernetes that you would use in a large-scale (non-lightweight) cluster setup.


## Lab Setup and hardware

* One master node for the control plan
* Two worker nodes for running the containerized workloads

| Server Role | Host Name  | Hardware<br>Configuration | IP Address |
|:-----------:|:----------:|:-------------------------:|:----------:|
| Master      | k8s-master | Chuwi Larxkbox X 2023 | 192.168.0.244 |
| Worker Node | k8s-node1  | Chuwi Larxkbox X 2023 | 192.168.0.242 |
| Worker Node | k8s-node2  | Chuwi Larxkbox X 2023 | 192.168.0.241 |


### Chuwi LarkBox X 2023 Mini PC specifications

These are only partial specs.

* Intel Alder Lake-N N100 (4 cores) Max Turbo 3.4 GHz
* 12GB LPDDR5 4800 MHz memory
* 512 GB SSD
* 1x USB-C, 4x USB-A, 2x RJ-45 10/100/1000 Mbps LAN


## My Installation

I followed the instructions starting on this [page](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/) in the Kubernetes documentation and went from there.  The below pages sent me to other subsequent websites as well.

* [Installing kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
* [Creating a cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/)


## Common Installation (Master and Worker nodes)

The following steps apply to both the master and worker nodes.

### Swap configuration

The default behavior of a kublet was to fail to start if swap memory was detected on a node (master or worker).  You must disable swap if the kubelet is not properly configured to use a swap file.

To disable swap temporarily (until a reboot):

~~~shell
sudo swapoff -a
~~~

To make this change permanent across reboots, you must disable it in the config files.  Different systems use different configurations. Ubuntu 24.04 LTS Server configures swap in the `/etc/fstab` file.  You just simply comment this line out.  Other systems may use another method like `systemd.swap`.

~~~shell
...
#/swap.img      none    swap    sw      0       0
...
~~~


### Confirm unique device hardware

It's very likely that hardware devices will be unique, but some virtual machines share the same values.

The following must be unique for every node (including the master node):

* **MAC address** - you can retrieve the MAC address by typing `ip link` or `ifconfig -a` (in Ubuntu, you will need the `net-tools` package if it isn't already installed)
* **product_uuid** - the product_uuid can be checked by using the command `sudo cat /sys/class/dmi/id/product_uuid`


### Check required ports

These [required ports](https://kubernetes.io/docs/reference/networking/ports-and-protocols/) need to be open in order for Kubernetes to properly operate. There are various ways to check if a port is open or being used, nut you can use tools like `netcat` to check.  For example:

~~~shell
nc 127.0.0.1 6443 -v
~~~


### Enable IPv4 packet forwarding

~~~shell
# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.ipv4.ip_forward = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
~~~

Verify that `net.ipv4.ip_forward` is set to 1 with:

~~~shell
sysctl net.ipv4.ip_forward
~~~


### cgroup drivers

On Linux, control groups are used to constrain resources that are allocated to processes.

> :information_source: **Note:**<br>
> Kubernetes v1.22 and later, when creating a cluster with kubeadm, if the user does not set the `cgroupDriver` field under `KubeletConfiguration`, kubeadm defaults it to `systemd`.

~~~yaml
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
...
cgroupDriver: systemd
~~~

By default (if using Kubernetes v1.22+), nothing needs to be set or changed.


### Installing a container runtime (Master and Worker nodes)

A container runtime lets each node run Pods, so installing one is required. There are a number of options, but we're going to install containerd.

1. Set up Docker's apt repository

    ~~~shell
    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    ~~~

2. Install the latest version of `containerd`

    ~~~shell
    sudo apt-get install containerd.io
    ~~~

3. Configure containerd

    This sets the default configuration for containerd.

    ~~~shell
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    ~~~

4. Update configuration

    Update the `/etc/containerd/config.toml` file to reflect these changes.

    ~~~shell
    [plugins."io.containerd.grpc.v1.cri".containerd]
      snapshotter = "overlayfs"
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
      SystemdCgroup = true
    ~~~

    > :information_source: **Note:**<br>
    > Confirm CRI support is enabled.<br>
    > Ensure that `cri` is not included in the `disabled_plugins` list within `/etc/containerd/config.toml`.

5. Restart containerd to apply changes and enable service start on system start-up

    ~~~shell
    sudo systemctl restart containerd
    sudo systemctl enable containerd
    ~~~


### Install Kubeadm, Kubectl, and Kubelet

Install Kubernetes v1.30.

1. Update the `apt` package index and install required packages to use the Kubernetes `apt` repository

    ~~~shell
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl gpg
    ~~~

2. Download the public signing key for the Kubernetes package repositories

    ~~~shell
    # If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
    # sudo mkdir -p -m 755 /etc/apt/keyrings
    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    ~~~

3. Add the appropriate Kubernetes apt repository

    ~~~shell
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    ~~~

4. Update the `apt` package index and install the packages

    ~~~shell
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    ~~~

5. Pin the package versions so they aren't updated automatically

    ~~~shell
    sudo apt-mark hold kubelet kubeadm kubectl
    ~~~


### Validate containerd status

First, install the `cri-tools` package.

~~~shell
sudo apt-get install cri-tools
sudo crictl -r unix:///var/run/containerd/containerd.sock info
~~~


## Master node Installation (Master node)

The following steps apply to only the master node.


### Network setup

kubeadm tries to find a usable IP on the network interfaces associated with a default gateway on a host. Such an IP is then used for advertising and/or listening performed by a component.

To find out what this IP is on a Linux host, you can use:

~~~shell
ip route show # Look for a line starting with "default via"
~~~


### Initialize control-plane node (Master node only)

> :warning: <span style="color:red;">**Warning**</span>:<br>
> Before proceeding with this step, the following criteria must be satisfied.
>
> * Worker nodes must be ready! (all previous steps completed)
> * Network connectivity/communication must be working between cluster nodes!
> * Kubeadm, Kubectl, and Kubelet must be installed and enabled!

Initialize the control-plane node.

The `--pod-network-cidr` must match the upcoming step where you install a Pod network add-on.  The default CIDR for the add-on I chose is `10.244.0.0/16`.  The `--v=5` flag enables level 5 verbosity of the `kubeadm init` command.

You should be picking a POD network CIDR that differs from your current network shown when running `ip route show`.

~~~shell
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --v=5
~~~

At the end of initialization, it should produce output similar to the following.

~~~shell
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

Then you can join any number of worker nodes by running the following on each as root:

sudo kubeadm join 192.168.0.244:6443 --token fnx7ph.3x6ev57614858739 \
        --discovery-token-ca-cert-hash sha256:dc5e05f4qbt8c87maqcywsacrx2xdqpqzobioiakukspmr773uz72zslr2h46m29
~~~

> :warning: <span style="color:red;">**Warning**</span>:<br>
> Make a record of the `kubeadm join` command that `kubeadm init` outputs. You need this command to join nodes
> to your cluster and it won't be shown again.

So you can access your cluster with the `kubectl` command, create your config.

~~~shell
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
~~~





### Installing a Pod network add-on (CNI)

You must deploy a Container Network Interface (CNI) based Pod network add-on so that your Pods can communicate with each other.
Cluster DNS (CoreDNS) will not start up before a network add-on is installed.

I decided to go with Canal, which provides a middle ground and gives you Calico for network policy and Flannel for basic networking.

> :information_source: **Note:**<br>
> There are several great articles that explain the differences.
>
> * [Flannel + Calico --> Canal - what's your ultimate k8s networking?](https://articles.aceso.no/untitled-4/)
> * [The Ultimate Guide To Using Calico, Flannel, Weave and Cilium](https://platform9.com/blog/the-ultimate-guide-to-using-calico-flannel-weave-and-cilium/)
> * [Comparing Kubernetes CNI Providers: Flannel, Calico, Canal, and Weave](https://www.suse.com/c/rancher_blog/comparing-kubernetes-cni-providers-flannel-calico-canal-and-weave/)
> * [Kubernetes CNI Comparison: Flannel vs Calico vs Canal](https://daily.dev/blog/kubernetes-cni-comparison-flannel-vs-calico-vs-canal)


1. Download the Canal networking manifest

    ~~~shell
    curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.1/manifests/canal.yaml -O
    ~~~

2. Install Canal (Flannel & Calico)

    ~~~shell
    kubectl apply -f canal.yaml
    ~~~

## Final steps

### Join the Kubernetes cluster (Worker node only)

The following command will join your worker node to the cluster. You must run this on each worker node.

~~~shell
sudo kubeadm join 192.168.0.244:6443 --token fnx7ph.3x6ev57614858739 \
    --discovery-token-ca-cert-hash sha256:dc5e05f4qbt8c87maqcywsacrx2xdqpqzobioiakukspmr773uz72zslr2h46m29
~~~

### Check cluster status

Check the status of the cluster.

~~~shell
kubectl cluster-info
~~~

You should see something similar to this snippet:

~~~shell
$ kubectl cluster-info
Kubernetes control plane is running at https://192.168.0.244:6443
CoreDNS is running at https://192.168.0.244:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
~~~

Check status of your nodes.

~~~shell
kubectl get nodes -o wide
~~~

This command should produce output similar to what you see below.

~~~shell
$ kubectl get nodes -o wide
NAME         STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE           KERNEL-VERSION     CONTAINER-RUNTIME
k8s-master   Ready    control-plane   40d   v1.30.2   192.168.0.244   <none>        Ubuntu 24.04 LTS   6.8.0-35-generic   containerd://1.6.33
k8s-node1    Ready    <none>          40d   v1.30.2   192.168.0.242   <none>        Ubuntu 24.04 LTS   6.8.0-36-generic   containerd://1.7.18
k8s-node2    Ready    <none>          33d   v1.30.2   192.168.0.241   <none>        Ubuntu 24.04 LTS   6.8.0-36-generic   containerd://1.7.18
~~~

## Conclusion

I've got my cluster all up and running.  Though I did hit a few snags during the whole process, I learned a lot and will continue to "play" with my cluster.  Hopefully hosting something useful in the future!
