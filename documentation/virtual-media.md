# Virtual Media Guide

This guide explains how to use Redfish virtual media to attach ISO images to KubeVirt virtual machines.

## Overview

Virtual media allows attaching ISO images to VMs over the network, enabling:

- Operating system installation from ISO
- Booting from recovery media
- Running live systems

KubeVirtBMC implements Redfish virtual media using KubeVirt's `DeclarativeHotplugVolumes` feature and CDI (Containerized Data Importer).

## Prerequisites

### 1. CDI Installation

CDI (Containerized Data Importer) must be installed:

```bash
# Check if CDI is installed
kubectl get crd datavolumes.cdi.kubevirt.io

# If not installed, see: https://github.com/kubevirt/containerized-data-importer
```

### 2. KubeVirt Feature Gate

The `DeclarativeHotplugVolumes` feature gate must be enabled:

```bash
# Check KubeVirt configuration
kubectl get kubevirt kubevirt -n kubevirt -o yaml | grep DeclarativeHotplugVolumes
```

If the feature gate is not enabled, enable it using the patch command:

```bash
kubectl patch kubevirt kubevirt -n kubevirt --type merge -p '{"spec":{"configuration":{"developerConfiguration":{"featureGates":["DeclarativeHotplugVolumes"]}}}}'
```

Ensure it's enabled in KubeVirt spec:

```yaml
spec:
  configuration:
    developerConfiguration:
      featureGates:
      - DeclarativeHotplugVolumes
```

### 3. VirtualMachine Configuration

Your VirtualMachine must have a CD-ROM disk defined:

```bash
kubectl apply -f - <<EOF
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
  namespace: default
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
          # CD-ROM disk required for virtual media
          - cdrom:
              bus: sata
            name: cdrom
          interfaces:
          - name: default
            masquerade: {}
        resources:
          requests:
            memory: 64Mi
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
      networks:
      - name: default
        pod: {}
EOF
```

**Important:**

- CD-ROM disk must exist in spec before using virtual media
- Bus type should be `sata` (recommended) or `scsi`
- Disk name can be any value (e.g., `cdrom`, `iso`, `dvd`)

## Inserting Virtual Media

### Using Redfish API

```bash
# First, create a session and get token
TOKEN=$(curl -s -i -X POST \
    -H "Content-Type: application/json" \
    http://testvm-virtbmc.default.svc/redfish/v1/SessionService/Sessions \
    -d '{"UserName":"admin","Password":"admin123"}' \
    | grep -i "X-Auth-Token" | cut -d' ' -f2 | tr -d '\r')

# Insert virtual media
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc/redfish/v1/Managers/BMC/VirtualMedia/CD1/Actions/VirtualMedia.InsertMedia \
    -d '{
        "Image": "https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso",
        "Inserted": true
    }'
```

### Request Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `Image` | string | Yes | HTTP/HTTPS URL to ISO image |
| `Inserted` | boolean | Yes | Set to `true` to insert media |

### Supported Image Sources

- HTTP URLs: `http://example.com/image.iso`
- HTTPS URLs: `https://example.com/image.iso`
- Public repositories: Ubuntu, CentOS, etc.
- Internal services: Services accessible from the cluster

### Example ISO URLs

```bash
# Ubuntu 24.04
"https://releases.ubuntu.com/noble/ubuntu-24.04.3-live-server-amd64.iso"

# CentOS Stream
"https://mirror.stream.centos.org/9-stream/BaseOS/x86_64/iso/CentOS-Stream-9-latest-x86_64-dvd1.iso"

# Internal service
"http://internal-iso-service.default.svc/image.iso"
```

## Checking Status

### Get Virtual Media Status

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc/redfish/v1/Managers/BMC/VirtualMedia/CD1
```

**Response includes:**

- `Image`: The ISO URL
- `Inserted`: Whether media is currently inserted
- `MediaTypes`: Supported types (CD, DVD)

## Ejecting Virtual Media

### Eject Virtual Media

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc/redfish/v1/Managers/BMC/VirtualMedia/CD1/Actions/VirtualMedia.EjectMedia \
    -d '{}'
```

**Note:** The request body must be an empty JSON object `{}`.

## Next Steps

- Read the [Redfish Guide](redfish-guide.md) for complete Redfish API usage
