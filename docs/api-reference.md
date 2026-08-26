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
  ipmi:
    enabled: false  # Optional, defaults to false
  storageClassName: string  # Optional, defaults to the cluster's default StorageClass
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `virtualMachineRef` | `LocalObjectReference` | Yes | Reference to the VirtualMachine to manage |
| `virtualMachineRef.name` | `string` | Yes | Name of the VirtualMachine resource |
| `authSecretRef` | `LocalObjectReference` | Yes | Reference to the Secret containing BMC credentials |
| `authSecretRef.name` | `string` | Yes | Name of the Secret resource |
| `ipmi` | `IPMISpec` | No | IPMI configuration. When omitted, IPMI is disabled. |
| `storageClassName` | `string` | No | StorageClass used for the DataVolume created on virtual media insert. When omitted, the cluster's default StorageClass is used. |

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

