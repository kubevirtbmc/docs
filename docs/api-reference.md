# API Reference

This document provides detailed reference for the KubeVirtBMC Custom Resource Definition (CRD).

## Table of Contents

- [VirtualMachineBMC](#virtualmachinebmc)
- [Specification](#specification)

## VirtualMachineBMC

The `VirtualMachineBMC` is a Custom Resource that represents a virtual BMC for a KubeVirt VirtualMachine.

### API Version

```
bmc.kubevirt.io/v1beta1
```

### Kind

```
VirtualMachineBMC
```

### Full Resource Name

```yaml
apiVersion: bmc.kubevirt.io/v1beta1
kind: VirtualMachineBMC
```

## Specification

### VirtualMachineBMCSpec

The `spec` section defines the desired state of the Virtual BMC.

```yaml
spec:
  virtualMachineRef:
    name: string  # Required
  authSecretRef:
    name: string  # Required
  service:
    type: ClusterIP  # Optional, defaults to ClusterIP
    labels: {}       # Optional
    annotations: {}  # Optional
  ipmi:
    enabled: false  # Optional, defaults to false
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `virtualMachineRef` | `LocalObjectReference` | Yes | Reference to the VirtualMachine to manage |
| `virtualMachineRef.name` | `string` | Yes | Name of the VirtualMachine resource |
| `authSecretRef` | `LocalObjectReference` | Yes | Reference to the Secret containing BMC credentials |
| `authSecretRef.name` | `string` | Yes | Name of the Secret resource |
| `service` | `BMCServiceSpec` | No | BMC Service configuration. When omitted, the Service defaults to type `ClusterIP`. |
| `ipmi` | `IPMISpec` | No | IPMI configuration. When omitted, IPMI is disabled. |

### BMCServiceSpec

BMCServiceSpec configures the Service the controller creates to expose the virtbmc Pod.

```yaml
service:
  type: LoadBalancer  # Optional, one of ClusterIP | NodePort | LoadBalancer, defaults to ClusterIP
  labels:              # Optional, merged with the controller's own labels
    team: infra
  annotations:          # Optional
    example.com/owner: "infra-team"
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `service.type` | `string` | No | Type of Service to create. One of `ClusterIP`, `NodePort`, or `LoadBalancer`. Defaults to `ClusterIP`. Changing this value deletes and recreates the Service. |
| `service.labels` | `map[string]string` | No | Additional labels applied to the Service, merged with the labels the controller sets for Pod selection. |
| `service.annotations` | `map[string]string` | No | Annotations applied to the Service, useful for cloud load balancer controllers, service meshes, or monitoring tooling. |

!!! note

    Changing `service.labels` or `service.annotations` patches the existing Service in place. Changing `service.type` deletes and recreates the Service, which changes its `ClusterIP` and might change previously assigned `NodePort`/`LoadBalancer` address.

### IPMISpec

IPMISpec configures the IPMI simulator.

```yaml
ipmi:
  enabled: false  # Optional, defaults to false
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `ipmi.enabled` | `bool` | No | Toggles the IPMI simulator. Defaults to `false` when omitted. Set to `true` to enable IPMI support. |

## Related Resources

- [KubeVirt VirtualMachine API](https://kubevirt.io/api-reference/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)


For the latest API specification, see the [CRD definition](https://github.com/kubevirtbmc/kubevirtbmc/blob/main/config/crd/bases/bmc.kubevirt.io_virtualmachinebmcs.yaml).

