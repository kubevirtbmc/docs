# Configuration Guide

This guide covers advanced configuration options for KubeVirtBMC.

## Table of Contents

- [Helm Chart Configuration](#helm-chart-configuration)
- [Image Configuration](#image-configuration)
- [Exposing Redfish Externally](#exposing-redfish-externally)
- [Secret Management](#secret-management)


## Helm Chart Configuration

For the complete Helm chart values reference, see the [values.yaml](https://github.com/kubevirtbmc/kubevirtbmc/blob/main/deploy/charts/kubevirtbmc/values.yaml) file.

## Image Configuration

If you want to use your own manager image, modify the image configuration:

```yaml
# Image configuration
image:
  repository: starbops/virtbmc-controller # Change to your own registry
  pullPolicy: IfNotPresent
  tag: "v0.7.0"
```

If you want to use your own virtbmc image, pass the image via controller flags:

```yaml
manager:
  args:
    - --agent-image-name=starbops/virtbmc
    - --agent-image-tag=v0.7.0
```

## Exposing Redfish Externally

Redfish can be exposed externally using Ingress, enabling access from outside the cluster.

> **Note:** The [ingress-nginx controller is retiring](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/). Consider using alternative ingress controllers such as Traefik or F5, or use the Gateway API instead.

### Prerequisites

1. Ingress controller installed 
2. cert-manager for TLS certificates

### Using Ingress

#### Step 1: Create ClusterIssuer (for TLS)

Create a ClusterIssuer using Let's Encrypt for production use:

```yaml
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
```


#### Step 2: Create Ingress for Each Virtual BMC

```yaml
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

### Secret Management

#### Using External Secrets Operator

You can use the [External Secrets Operator](https://external-secrets.io/latest/) to manage secrets from external secret management systems:

## Next Steps

- Read [Getting Started Guide](getting-started.md) for installation instructions

