---
layout: post
title: Setting up Longhorn for Kubernetes storage
sitemap: false
hide_last_modified: true
---

When it came time to install the flight check-in app that I had created into my Kubernetes cluster, I realized I have no way for my workloads to utilize storage. Then I came across Longhorn during a web search for storage solutions. I suppose there are other options like Ceph. Initially forgetting about the Ceph option, I decided to go with Longhorn and I'm glad I did because some of the things I read about Ceph made it sound like a bad choice for a small bare metal Kubernetes cluster. But honestly, there are pros and cons to both Longhorn and Ceph.

# Longhorn setup
Longhorn (one of the pros) was extremely easy to setup (I read that's not the case with Ceph), all I did was follow this [page](https://longhorn.io/docs/1.7.2/deploy/install/). I ran the [Environment Check Script](https://longhorn.io/docs/1.7.2/deploy/install/#using-the-environment-check-script), which is actually deprecated and will be removed soon (in v1.8.0). It was replaced by the Longhorn Command Line Tool (I ran that tool as well). These are the steps I followed.

1. Run Environment Check Script

   ```shell
   curl -sSfL https://raw.githubusercontent.com/longhorn/longhorn/v1.7.2/scripts/environment_check.sh | bash
   ```

   The output stated that I needed to install the package, `nfs-common` and load a module, `iscsi_tcp`.


2. Run Longhorn Command Line Tool

   ```shell
   curl -sSfL -o longhornctl https://github.com/longhorn/cli/releases/download/v1.7.2/longhornctl-linux-amd64
   chmod +x longhornctl
   ./longhornctl check preflight
   ```

   The output of the Longhorn Command Line Tool stated that I additionally needed to load the module, `dm_crypt`.

3. On worker nodes 1 and 2, as previously stated, I had to install the package `nfs-common` and load a couple of modules.

   ```shell
   sudo apt install nfs-common
   sudo modprobe iscsi_tcp
   sudo modprobe dm_crypt
   ```
   Then put the modules in `/etc/modules-load.d/` so they load automatically if and when the system reboots.

   ```shell
   sudo tee /etc/modules-load.d/longhorn-storage.conf<<EOF
   iscsi_tcp
   dm_crypt
   EOF
   ```

   You must re-read values from all system directories.

   ```shell
   sudo sysctl --system
   ```

4. Install Longhorn via Helm

   ```shell
   helm repo add longhorn https://charts.longhorn.io
   helm repo update
   helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace --version 1.7.2
   ```

5. Last step is to create the StorageClass.

   ```yaml
   kind: StorageClass
   apiVersion: storage.k8s.io/v1
   metadata:
     name: longhorn
   provisioner: driver.longhorn.io
   allowVolumeExpansion: true
   reclaimPolicy: Delete
   volumeBindingMode: Immediate
   parameters:
     numberOfReplicas: "3"
     staleReplicaTimeout: "2880"
     fromBackup: ""
     fsType: "ext4"
   ```

That's it! I'm now able to use my Longhorn storage!

# Links

* [DevOps GitHub repo](https://github.com/jdstone/devops/tree/main/kubernetes/home_lab)
