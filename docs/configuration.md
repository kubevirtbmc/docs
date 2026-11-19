# Configuration Guide

This guide covers advanced configuration options for KubeVirtBMC.

## Table of Contents

- [Helm Chart Configuration](#helm-chart-configuration)
- [Image Configuration](#image-configuration)
- [Configuring the BMC Service Type](#configuring-the-bmc-service-type)
- [Attaching an Additional Network](#attaching-an-additional-network)
- [Exposing Redfish Externally](#exposing-redfish-externally)
- [Secret Management](#secret-management)


## Helm Chart Configuration

For the complete Helm chart values reference, see the [values.yaml](https://github.com/kubevirtbmc/kubevirtbmc/blob/main/deploy/charts/kubevirtbmc/values.yaml) file.

## Image Configuration

If you want to use your own manager image, modify the image configuration:

```yaml
# Image configuration
image:
  repository: kubevirtbmc/virtbmc-controller # Change to your own registry
  pullPolicy: IfNotPresent
  tag: "v0.7.0"
```

If you want to use your own virtbmc image, pass the image via controller flags:

```yaml
manager:
  args:
    - --agent-image-name=kubevirtbmc/virtbmc
    - --agent-image-tag=v0.7.0
```

## Configuring the BMC Service Type

By default, KubeVirtBMC exposes each Virtual BMC through a `ClusterIP` Service, reachable only from inside the cluster. Set `spec.service.type` on the `VirtualMachineBMC` resource to `NodePort` or `LoadBalancer` to expose it externally without needing an Ingress or Gateway. Use `spec.service.labels` and `spec.service.annotations` to attach metadata consumed by cloud load balancer controllers, service meshes, or monitoring tooling.

!!! note

    Changing `spec.service.type` deletes and recreates the underlying Service, which changes its `ClusterIP` and any previously assigned `NodePort`/`LoadBalancer` address. Changing `spec.service.labels` or `spec.service.annotations` patches the existing Service in place and does not cause a recreation.

### Example: LoadBalancer with Labels and Annotations

This example provisions a `LoadBalancer` Service and attaches a custom label plus an annotation consumed by your cloud provider's load balancer controller. For instance, [kube-vip](https://kube-vip.io/docs/usage/kubernetes-services/) reads the `kube-vip.io/loadbalancerIPs` annotation to assign a specific IP address to the Service:

```bash
kubectl apply -f - <<EOF
apiVersion: bmc.kubevirt.io/v1beta1
kind: VirtualMachineBMC
metadata:
  name: test-bmc
  namespace: default
spec:
  virtualMachineRef:
    name: testvm
  authSecretRef:
    name: bmc-secret
  service:
    type: LoadBalancer
    labels:
      team: infra
      app.kubernetes.io/part-of: kubevirtbmc
    annotations:
      kube-vip.io/loadbalancerIPs: 192.168.0.101
EOF
```

Verify the Service and the resulting `VirtualMachineBMC` status once kube-vip assigns the requested external IP:

```bash
kubectl get service testvm-virtbmc
kubectl get virtualmachinebmc test-bmc -o jsonpath='{.status.loadBalancerIP}{"\n"}'
```

Expected output:

```
NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
testvm-virtbmc    LoadBalancer   10.43.230.200   192.168.0.101   623/UDP,80/TCP   2m

192.168.0.101
```

### Example: NodePort

```bash
kubectl apply -f - <<EOF
apiVersion: bmc.kubevirt.io/v1beta1
kind: VirtualMachineBMC
metadata:
  name: test-bmc
  namespace: default
spec:
  virtualMachineRef:
    name: testvm
  authSecretRef:
    name: bmc-secret
  service:
    type: NodePort
EOF
```

```bash
kubectl get service testvm-virtbmc
```

```
NAME             TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)                       AGE
testvm-virtbmc   NodePort   10.43.230.200   <none>        623:31623/UDP,80:31080/TCP   2m
```

## Attaching an Additional Network

By default, the virtBMC Pod is only connected to the cluster's default Pod network. Set `spec.networkRef` on the `VirtualMachineBMC` resource to attach one additional [Multus](https://github.com/k8snetworkplumbingwg/multus-cni) network to the virtBMC Pod, for example to place the BMC endpoints on a dedicated out-of-band management network. The default Pod network, and the BMC Service, are kept.

`spec.networkRef` references a `NetworkAttachmentDefinition` as either:

- `name`: a `NetworkAttachmentDefinition` in the same namespace as the `VirtualMachineBMC`
- `namespace/name`: a `NetworkAttachmentDefinition` in another namespace

!!! note

    Changing `spec.networkRef` (setting, updating, or removing it) recreates the virtBMC Pod. Active IPMI and Redfish sessions are dropped while the new Pod starts.

### Prerequisites

1. [Multus CNI](https://github.com/k8snetworkplumbingwg/multus-cni) installed in the cluster
2. A `NetworkAttachmentDefinition` describing the network to attach

### Example: Attaching a Management Network

#### Step 1: Create a NetworkAttachmentDefinition

This example uses the `macvlan` CNI plugin on the host's `eth1` interface with static `host-local` IPAM. Adjust the CNI configuration to match your environment:

```bash
kubectl apply -f - <<'EOF'
apiVersion: k8s.cni.cncf.io/v1
kind: NetworkAttachmentDefinition
metadata:
  name: mgmt-net
  namespace: default
spec:
  config: |
    {
      "cniVersion": "0.3.1",
      "type": "macvlan",
      "master": "eth1",
      "mode": "bridge",
      "ipam": {
        "type": "host-local",
        "subnet": "192.168.100.0/24",
        "rangeStart": "192.168.100.10",
        "rangeEnd": "192.168.100.200"
      }
    }
EOF
```

#### Step 2: Reference the Network from the VirtualMachineBMC

```bash
kubectl apply -f - <<EOF
apiVersion: bmc.kubevirt.io/v1beta1
kind: VirtualMachineBMC
metadata:
  name: test-bmc
  namespace: default
spec:
  virtualMachineRef:
    name: testvm
  authSecretRef:
    name: bmc-secret
  networkRef: mgmt-net
EOF
```

The controller adds the `k8s.v1.cni.cncf.io/networks` annotation to the virtBMC Pod template, and Multus attaches the network when the Pod starts.

#### Step 3: Verify the Attached Network

Once Multus attaches the network, the controller reports it in `status.network` and sets the `NetworkAttached` condition to `True`. The `NETWORK` and `NETWORKIP` columns are shown with `-o wide`:

```bash
kubectl get virtualmachinebmc test-bmc -o wide
kubectl get virtualmachinebmc test-bmc -o jsonpath='{.status.network}{"\n"}'
```

Example output:

```
{"interface":"net1","ips":["192.168.100.10"],"mac":"36:9c:52:96:83:e9","name":"default/mgmt-net"}
```

The BMC endpoints are then reachable directly on the attached network's IP address. Traffic on this interface does not go through the BMC Service, so use the virtBMC container ports: `10080` for Redfish and `10623` for IPMI (when `spec.ipmi.enabled` is `true`):

```bash
curl http://192.168.100.10:10080/redfish/v1
ipmitool -I lanplus -H 192.168.100.10 -p 10623 -U admin -P password power status
```

### Troubleshooting

While the network is not attached, `status.network` is empty, the `NetworkAttached` condition is `False`, and its reason explains why:

| Reason | Meaning |
|--------|---------|
| `MultusNotInstalled` | The `NetworkAttachmentDefinition` CRD is not present in the cluster. Install Multus. |
| `NetworkAttachmentDefinitionNotFound` | The referenced `NetworkAttachmentDefinition` does not exist. The virtBMC Pod will not start until it is created. |
| `NetworkAttachmentPending` | The `NetworkAttachmentDefinition` exists but Multus has not attached it yet. Check the virtBMC Pod events if this persists. |

```bash
kubectl get virtualmachinebmc test-bmc \
  -o jsonpath='{.status.conditions[?(@.type=="NetworkAttached")]}{"\n"}'
```

The admission webhook also returns warnings (not errors) when the `NetworkAttachmentDefinition` or its CRD is missing, since they may be created after the `VirtualMachineBMC`. A malformed `spec.networkRef` (anything other than `name` or `namespace/name`) is rejected.

### Restricting Cross-Namespace Networks

Referencing a `NetworkAttachmentDefinition` in another namespace is allowed and returns an admission warning. To block it, enable `namespaceIsolation` in Multus. This is a Multus setting, not a KubeVirtBMC one.

!!! note

    Even with `namespaceIsolation` enabled, `NetworkAttachmentDefinitions` in the `default` namespace, and in any namespace listed in `globalNamespaces`, remain usable from all namespaces. See [Multus Namespace Isolation](https://github.com/k8snetworkplumbingwg/multus-cni/blob/master/docs/configuration.md#namespace-isolation).

## Exposing Redfish Externally

Redfish can be exposed externally using Ingress, enabling access from outside the cluster.

!!! note

    The [ingress-nginx controller has retired](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Consider using alternative ingress controllers such as Traefik or F5, or use the Gateway API instead.

### Prerequisites

1. Ingress controller installed 
2. cert-manager for TLS certificates

### Using Ingress:

#### Step 1: Create ClusterIssuer (for TLS)

Create a ClusterIssuer using Let's Encrypt for production use:

```bash
kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Replace this email address with your own.
    email: abc@org.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: prod-letsencrypt-account-key
    solvers:
    - http01:
        ingress:
          ingressClassName: <ingressClassName>
EOF
```


#### Step 2: Create Ingress for Each Virtual BMC

```bash
kubectl apply -f - <<'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-vm-virtbmc
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    traefik.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: traefik  # Should match the ingressClassName in ClusterIssuer
  tls:
  - hosts:
    - my-vm-bmc.example.com
    secretName: my-vm-virtbmc-tls
  rules:
  - host: my-vm-bmc.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: my-vm-virtbmc
            port:
              number: 80
EOF
```

#### Step 3: Access Redfish Externally

```bash
# Access via HTTPS
curl https://my-vm-bmc.example.com/redfish/v1

# Create session
curl -k -i -X POST \
    -H "Content-Type: application/json" \
    https://my-vm-bmc.example.com/redfish/v1/SessionService/Sessions \
    -d '{"UserName":"admin","Password":"password"}'
```

### Using Kubernetes GatewayAPI:

Redfish can also be exposed externally using the Kubernetes Gateway API, enabling secure access from outside the cluster without requiring a traditional Ingress resource.

This example uses Istio as the Gateway API implementation and cert-manager to automatically provision TLS certificates from Let's Encrypt. Review specific implementation documentation for installing them.

!!! note

    cert-manager Gateway API support is not enabled by default. To automatically provision TLS certificates from Gateway resources, cert-manager must be installed with the --enable-gateway-api option.

#### Prerequisites
1. Gateway API CRDs installed
2. A Gateway API implementation installed (Istio, Traefik, Envoy Gateway, Kong, etc.)
3. cert-manager for TLS certificates
4. A publicly accessible hostname that resolves to the Gateway external IP address

#### Step 1: Enable Gateway API Support in cert-manager

1. Verify whether Gateway API support is enabled:

    ```bash
    kubectl -n cert-manager get deployment cert-manager -o yaml | grep -i enable-gateway-api
    ```

    If the output is empty, proceed with the next step.


2. To add the GatewayAPI support and if cert-manager was installed using Helm chart, run:

    ```bash
    helm upgrade cert-manager jetstack/cert-manager --namespace cert-manager --reuse-values --set extraArgs="{--enable-gateway-api}"
    ```

3. Alternatively, if it was installed using manifest:

    ```bash
    kubectl patch deployment cert-manager -n cert-manager --type=json -p='[ { "op":"add", "path":"/spec/template/spec/containers/0/args/-", "value":"--enable-gateway-api" } ]'
    ```

4. Verify if the deployment rolled out successfully:

    ```bash
    kubectl rollout status deployment cert-manager -n cert-manager
    ```

#### Step 2: Create ClusterIssuer (for TLS)

```bash
kubectl apply -f - <<'EOF'
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    # Replace this email address with your own.
    email: abc@org.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod-account-key
    solvers:
    - http01:
        gatewayHTTPRoute:
          parentRefs:
          - group: gateway.networking.k8s.io
            kind: Gateway
            name: bmc-gateway
            namespace: default
EOF
```

Verify that the ClusterIssuer becomes ready:

```bash
kubectl get clusterissuer
```

Example output:

```bash
kubectl get clusterissuer
NAME               READY   AGE
letsencrypt-prod   True    146m
```

#### Step 3: Create Gateway Resource 

Create a Gateway with both HTTP and HTTPS listeners. The HTTP listener is required for cert-manager HTTP-01 challenge validation.

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: bmc-gateway
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  gatewayClassName: istio
  listeners:
  - name: http
    protocol: HTTP
    port: 80
    hostname: "my-vm-bmc.example.com"
    allowedRoutes:
      namespaces:
        from: Same
  - name: https
    protocol: HTTPS
    port: 443
    hostname: "my-vm-bmc.example.com"
    tls:
      mode: Terminate
      certificateRefs:
      - group: ""
        kind: Secret
        name: my-vm-bmc-tls    # This secret gets created automatically by cert-manager and manage it as referenced by the Gateway.
    allowedRoutes:
      namespaces:
        from: Same
EOF
```

#### Step 4: Create HTTPRoute Resource for Each Virtual BMC

Create an HTTPRoute that forwards Redfish traffic to the VirtualBMC Service.

```bash
kubectl apply -f - <<'EOF'
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: testbmc-route
  namespace: default
spec:
  parentRefs:
  - group: gateway.networking.k8s.io
    kind: Gateway
    name: bmc-gateway
  hostnames:
  - "my-vm-bmc.example.com"
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /redfish/v1
    backendRefs:
    - name: testvm-virtbmc
      port: 80
EOF
```

#### Step 5: Verify the resources

Monitor certificate creation:

```bash
kubectl get certificate
```

Once certificate issuance completes successfully:

```bash
kubectl get secret my-vm-bmc-tls
```

Example output:

```bash
NAME                TYPE                DATA   AGE
my-vm-virtbmc-tls   kubernetes.io/tls   2      1m
```

Verify the Gateway:

```bash
kubectl get gateway
```

Example output:

```bash
NAME          CLASS   ADDRESS          PROGRAMMED
bmc-gateway   istio   203.10.11.12     True
```

Verify the HTTPRoute:

```bash
kubectl get httproute
```

Expected output:

```bash
kubectl get httproute 
NAME            HOSTNAMES                                    AGE
testbmc-route   ["my-vm-bmc.example.com"]                    106m
```

#### Step 5: Access Redfish Externally

```bash
# Access via HTTPS
curl https://my-vm-bmc.example.com/redfish/v1

# Create session
curl -k -i -X POST \
    -H "Content-Type: application/json" \
    https://my-vm-bmc.example.com/redfish/v1/SessionService/Sessions \
    -d '{"UserName":"admin","Password":"admin123"}'
```

### Secret Management

#### Using External Secrets Operator

You can use the [External Secrets Operator](https://external-secrets.io/latest/) to manage secrets from external secret management systems:

## Next Steps

- Read [Getting Started Guide](getting-started.md) for installation instructions

