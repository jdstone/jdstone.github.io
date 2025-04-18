---
layout: post
title: Install Kubernetes Metrics Server
sitemap: false
hide_last_modified: true
---

Want to be able to easily see what Kubernetes pod has the highest CPU load (among other information) by using the `kubectl top` command? Install the Kubernetes metrics-server!


1. `kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml`
2. Edit the metrics-server deployment to disable TLS certificate validation. Otherwise, the Metrics Server pod won't start. Add `--kubelet-insecure-tls` to the args of the metrics-server container. `kubectl edit deploy metrics-server`


```
apiVersion: apps/v1
kind: Deployment
metadata:
  name: metrics-server
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - args:
        - --kubelet-insecure-tls #    <----- ADD THIS
        name: metrics-server
...
```

> :warning: <span style="color:red;">**Caution**</span>:<br>
> Don't use this to forward metrics to a monitoring solution. Metrics Server is meant only for Kubernetes autoscaling purposes (and to be able to use this command).
