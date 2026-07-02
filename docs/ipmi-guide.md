# IPMI Guide

This guide covers using IPMI (Intelligent Platform Management Interface) with KubeVirtBMC for out-of-band management of virtual machines.

## Overview

IPMI is a standardized UDP-based protocol for chassis control. KubeVirtBMC implements IPMI chassis commands for power management and boot device configuration.

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
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" <command>
```

Delete the pod when done:

```bash
kubectl delete pods ipmitool
```

## Power Management

### Power Status

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power status
```

#### **Output:**
- `Chassis Power is on` - VM is running
- `Chassis Power is off` - VM is stopped

### Power On

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power on

```

### Power Off (Graceful)

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power off

```

Sends ACPI shutdown signal. VM must support ACPI for graceful shutdown.

### Power Cycle

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power cycle
```

Powers off, waits briefly, then powers on.


### Power Commands Summary

| Command | Description | Graceful |
|---------|-------------|----------|
| `power on` | Start VM | N/A |
| `power off` | Shutdown VM | Yes |
| `power cycle` | Off then On | Partial |

## Boot Device Configuration

### Set Boot to PXE

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe
```

### Set Boot to Disk

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk
```

### Set Boot to CD-ROM

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom
```

### Supported Boot Devices

| Device | Description |
|--------|-------------|
| `pxe` | Network boot (PXE) |
| `disk` | Boot from disk |
| `cdrom` | Boot from CD-ROM |

## Next Steps

- Read the [Redfish Guide](redfish-guide.md) for RESTful API access
