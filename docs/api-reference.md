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
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `virtualMachineRef` | `LocalObjectReference` | Yes | Reference to the VirtualMachine to manage |
| `virtualMachineRef.name` | `string` | Yes | Name of the VirtualMachine resource |
| `authSecretRef` | `LocalObjectReference` | Yes | Reference to the Secret containing BMC credentials |
| `authSecretRef.name` | `string` | Yes | Name of the Secret resource |


## Related Resources

- [KubeVirt VirtualMachine API](https://kubevirt.io/api-reference/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)


For the latest API specification, see the [CRD definition](https://github.com/kubevirtbmc/kubevirtbmc/blob/main/config/crd/bases/bmc.kubevirt.io_virtualmachinebmcs.yaml).

