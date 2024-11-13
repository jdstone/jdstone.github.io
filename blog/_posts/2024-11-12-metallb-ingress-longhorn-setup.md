---
layout: post
title: How I added MetalLB and an Nginx Ingress Controller to my Kubernetes cluster
sitemap: true
hide_last_modified: true
---


To be able to run Kubernetes (K8s) workloads, it's helpful to be able to utilize a K8s ingress. Utilizing a K8s ingress without a Load Balancer (LB) is possible, but can be somewhat limiting. That's where these various open source projects come in that I will be utilizing with my K8s cluster.


# MetalLB

Kubernetes does not include an implementation of network load balancers for bare metal clusters, like mine. Load balancers are typically only available in cloud environments like GCP, AWS, and Azure. For bare metal clusters, what Kubernetes does offer is two lesser tools to bring user traffic into their clusters, "NodePort" and "externalIPs" type services. Though both of these have significant downsides for production use.

MetalLB aims to resolve this by implementing a load balancer for bare metal Kubernetes clusters. A load balancer distributes a set of tasks evenly over a set of computing resources. This way, no one server is saddled with all the work, while the others just sit around and do nothing.

MetalLB can operate in two different modes, layer 2 mode or BGP mode. In layer 2 mode, you don't need any protocol-specific configuration, only IP addresses. This makes it ideal for home use, where most people (including myself) don't have more advanced routers with BGP capability. This mode works a little differently and is not "true" load balancing (in the traditional sense). As MetalLB states, "it implements a failover mechanism so that a different node can take over should the current leader node fail for some reason". In this mode, "all traffic for a service IP goes to one node". "From there, kube-proxy spreads the traffic to all the service's pods". However, this comes with its own limitations such as single-node bottlenecking and potentially slow failover.

## Installation & Configuration

If I were running my Kubernetes cluster with kube-proxy in IPVS mode, I'd have to enable strict ARP mode, per the Metal LB [preparation](https://metallb.io/installation/#preparation) guide.

For my installation, I installed with Helm.

```shell
helm repo add metallb https://metallb.github.io/metallb
helm install -n metallb-system --create-namespace metallb metallb/metallb
```

Since my Kubernetes cluster is not on the public facing internet and is behind my router, I had to pick my pool of (internal) IP addresses that the LB would allocate from, rather than external IPs. I also had to create the L2 Advertisement so MetalLB is aware of the IP address pool.

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.2-192.168.0.5
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: my-l2advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - first-pool
```


# Nginx Ingress Controller

With my load balancer installed, I could now move onto installing an ingress controller. There are a few offerings for ingress controllers out there, but I chose the Nginx ingress controller, as I have previous experience.

The installation was pretty smooth and consisted of only a few steps. <small>(steps may not be exactly as ran)</small>

```shell
helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

Once that was complete, I could install an application into Kubernetes and create an ingress resource for it. I installed a simple "snake" game and created the ingress as shown below. <small>(snake Kubernetes service resource not shown)</small>

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: snake-demo
  namespace: default
spec:
  ingressClassName: nginx
  rules:
  - host: snake.home.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: snake
            port:
              number: 80
```


In conclusion, my cluster is now ready to host applications. Look forward to a new article describing a new app that I developed that will be running in my cluster.
