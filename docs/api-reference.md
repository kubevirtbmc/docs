# API Reference

This document provides detailed reference for the KubeVirtBMC Custom Resource Definition (CRD).

## Table of Contents

- [VirtualMachineBMC](#virtualmachinebmc)
- [Specification](#specification)
- [RedfishSpec](#redfishspec)

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
  redfish:
    virtualMedia:
      storage:
        storageClassName: fast  # Optional, defaults to the cluster's default StorageClass
        volumeMode: Block       # Optional, one of Filesystem | Block, defaults to Block
      tls:
        insecureSkipVerify: false            # Optional, defaults to false
        caBundleConfigMapRef:
          name: string                       # Optional
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
| `redfish` | `RedfishSpec` | No | Redfish configuration. Redfish is always enabled; when omitted, virtual media uses default settings. |

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

### RedfishSpec

RedfishSpec configures the Redfish interface and virtual media settings.

```yaml
redfish:
  virtualMedia:
    storage:
      storageClassName: fast  # Optional, defaults to the cluster's default StorageClass
      volumeMode: Block       # Optional, one of Filesystem | Block, defaults to Block
    tls:
      insecureSkipVerify: false            # Optional, defaults to false
      caBundleConfigMapRef:
        name: string                       # Optional
```

#### Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `redfish.virtualMedia` | `VirtualMediaSpec` | No | Configures the DataVolume created on virtual media insert. |
| `redfish.virtualMedia.storage` | `VirtualMediaStorageSpec` | No | Configures the storage backing the DataVolume. |
| `redfish.virtualMedia.storage.storageClassName` | `string` | No | StorageClass used for the DataVolume created on virtual media insert. When omitted, the cluster's default StorageClass is used. |
| `redfish.virtualMedia.storage.volumeMode` | `string` | No | Volume mode for the DataVolume created on virtual media insert. One of `Filesystem` or `Block`. Defaults to `Block`, which has no filesystem overhead and so isn't subject to the StorageClass's CDI `filesystemOverhead` setting. Set to `Filesystem` for a volume with a filesystem instead, e.g. when the StorageClass's provisioner doesn't support raw block volumes. |
| `redfish.virtualMedia.tls` | `VirtualMediaTLSSpec` | No | Configures TLS behavior when fetching virtual media images over https. |
| `redfish.virtualMedia.tls.insecureSkipVerify` | `bool` | No | Disables TLS certificate verification when fetching a virtual media image over https. Defaults to `false`. Use with caution — see the [Virtual Media Guide](virtual-media.md#tls-for-private-or-self-signed-https-images). |
| `redfish.virtualMedia.tls.caBundleConfigMapRef` | `LocalObjectReference` | No | References a ConfigMap, in the same namespace as the `VirtualMachineBMC`, containing a CA bundle under the key `ca.pem`, trusted when fetching a virtual media image over https. |
| `redfish.virtualMedia.tls.caBundleConfigMapRef.name` | `string` | No | Name of the ConfigMap resource. |

See [Selecting a StorageClass](virtual-media.md#selecting-a-storageclass), [Selecting a Volume Mode](virtual-media.md#selecting-a-volume-mode), and [TLS for Private or Self-Signed HTTPS Images](virtual-media.md#tls-for-private-or-self-signed-https-images) for usage details.

### Annotations

In addition to `spec` fields, KubeVirtBMC reads the following annotations on the `VirtualMachineBMC` resource's `metadata.annotations`:

| Annotation | Type | Description |
|------------|------|-------------|
| `bmc.kubevirt.io/datavolume-size-margin` | `string` (integer) | Pads the size requested for the DataVolume created on virtual media insert by this many percent. Absent or invalid values default to `0` (no padding); invalid values are logged as a warning. |

See [Storage Overhead](virtual-media.md#storage-overhead) for usage details.

## Related Resources

- [KubeVirt VirtualMachine API](https://kubevirt.io/api-reference/)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)


For the latest API specification, see the [CRD definition](https://github.com/kubevirtbmc/kubevirtbmc/blob/main/config/crd/bases/bmc.kubevirt.io_virtualmachinebmcs.yaml).

