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

    **Recommendation:** For production use, we recommend using the [Redfish API](redfish-guide.md) which provides better security and modern RESTful access.

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

KubeVirtBMC implements IPMI chassis control commands per [IPMI specification §28.3](https://www.intel.com/content/www/us/en/products/docs/servers/ipmi/ipmi-second-gen-interface-spec-v2-rev1-1.html). Each `ipmitool power` subcommand maps to a specific chassis control operation:

| `ipmitool` Command | Chassis Control | KubeVirtBMC Method | Behavior |
|---------------------|-----------------|-------------------|----------|
| `power off` | Power Down (0x00) | `ForcePowerOff()` | Immediate power off — stops the VM instantly without OS notification |
| `power soft` | ACPI Soft (0x05) | `PowerOff()` | Graceful ACPI shutdown — sends shutdown signal to the guest OS |
| `power on` | Power Up (0x01) | `PowerOn()` | Start the VM |
| `power cycle` | Power Cycle (0x02) | `ForcePowerCycle()` | Force power cycle — immediately cuts power and restores the VM without OS notification |
| `power reset` | Hard Reset (0x03) | `PowerCycle()` | System reset — resets the VM without removing power, like pressing the reset button |

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

### Power Off (Immediate)

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power off
```

Immediately stops the VM without OS notification. This is equivalent to pulling the power cord on a physical machine.

### Power Soft (ACPI Graceful Shutdown)

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power soft
```

Sends an ACPI shutdown signal to the guest OS. The VM must support ACPI for graceful shutdown.

### Power Cycle (Force)

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power cycle
```

Immediately cuts power and restores it to the VM without OS notification. This is the most brutal power operation — equivalent to pulling the power cord and plugging it back in on a physical machine. The VM is forcefully stopped, then started again.

### Power Reset (System Reset)

```bash
ipmitool -I lan -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" power reset
```

Resets the VM without removing power. This is equivalent to pressing the reset button on a physical machine — less brutal than a full power cycle since power is maintained throughout.


### Power Commands Summary

| Command | Description | Graceful |
|---------|-------------|----------|
| `power on` | Start VM | N/A |
| `power off` | Immediate power off | No |
| `power soft` | ACPI graceful shutdown | Yes |
| `power cycle` | Force power cycle (cut and restore power) | No |
| `power reset` | System reset (restart without power removal) | No |

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
