# IPMI Guide

This guide covers using IPMI (Intelligent Platform Management Interface) with KubeVirtBMC for out-of-band management of virtual machines.

## Overview

IPMI is a standardized UDP-based protocol for chassis control. KubeVirtBMC implements IPMI chassis commands for power management and boot device configuration.

!!! note "IPMI Capability"

    In the new version, we have support for dual-stack IPMI v1.5 (RMCP) and v2.0 (RMCP+).
    Therefore, you can use either `ipmitool -I lan` or `ipmitool -I lanplus`.

**Service Endpoint:**
```
<vm-name>-virtbmc.<namespace>.svc.cluster.local:623
```

!!! note "IPMI Toggle"

    **IPMI Toggle:** IPMI is disabled by default. To enable IPMI, set `spec.ipmi.enabled` to `true` in the VirtualMachineBMC resource:
    ```yaml
    spec:
      ipmi:
        enabled: true
    ```

    **Recommendation:** For production use, we recommend using the [Redfish API](redfish-guide.md) which provides modern RESTful access.

## Accessing IPMI

### Run IPMI Client in Pod (Recommended)

Since IPMI uses UDP and requires cluster network access, run an IPMI client pod:

```bash
kubectl run ipmitool \
    --image=mikeynap/ipmitool \
    --restart=Never \
    --command -- sleep 9999999
```

```bash
kubectl exec -it ipmitool -- /bin/sh
```

Inside the pod, set environment variables for reuse:

```bash
export USERNAME="admin"
export PASSWORD="admin123"
export HOSTNAME="testvm-virtbmc.default.svc.cluster.local"  # <vmbmc-svc-name>.<namespace>.svc.cluster.local
```

!!! note

    The authentication credentials are retrieved from Secret configurations.

Then use the environment variables in all ipmitool commands:

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" <command>
```

Delete the pod when done:

```bash
kubectl delete pods ipmitool
```

## Power Management

### Power Status

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power status
```

#### **Output:**
- `Chassis Power is on` - VM is running
- `Chassis Power is off` - VM is stopped

### Power On

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power on
```

### Power Off (Forceful)

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power off
```

Immediate power down without OS notification.

### Power Off (Graceful / ACPI Soft Shutdown)

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power soft
```

Sends ACPI shutdown request to the guest OS for a graceful stop. Requires ACPI support in the guest.

### Power Cycle

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power cycle
```

Forces the VM to power off then immediately power back on.

### Hard Reset

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power reset
```

Forcefully resets the VM without cutting power, keeping it running.

### Power Commands Summary

| Command | Description | Graceful |
|---------|-------------|----------|
| `power on` | Start VM | N/A |
| `power off` | Force stop VM (immediate) | No |
| `power soft` | Graceful shutdown via ACPI | Yes |
| `power cycle` | Force off then on | No |
| `power reset` | Force reset without power off | No |

## Boot Device Configuration

### Set Boot to PXE

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe
```

### Set Boot to Disk

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk
```

### Set Boot to CD-ROM

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom
```

### Supported Boot Devices

| Device | Description |
|--------|-------------|
| `pxe` | Network boot (PXE) |
| `disk` | Boot from disk |
| `cdrom` | Boot from CD-ROM |

## Next Steps

- Read the [Redfish Guide](redfish-guide.md) for RESTful API access
