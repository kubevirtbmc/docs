# IPMI Guide

This guide covers using IPMI (Intelligent Platform Management Interface) with KubeVirtBMC for out-of-band management of virtual machines.

## Overview

IPMI is a standardized UDP-based protocol for chassis control. KubeVirtBMC implements IPMI chassis commands for power management and boot device configuration.

**Service Endpoint:**
```
<vm-name>-virtbmc.<namespace>.svc.cluster.local:623
```

**NOTE: IPMI Security and Future Plans**
> 
> IPMI support in KubeVirtBMC currently only supports IPMI v1, which is rarely used nowadays. The underlying IPMI library dependency is unmaintained, raising security concerns.
> 
> **Authentication Limitation:** Since IPMI is a UDP-based protocol without a backend server for authentication, any username and password combination will be accepted. Credentials are validated at the protocol level by the IPMI library, but there is no server-side authentication mechanism. This is a fundamental limitation of the IPMI protocol implementation in KubeVirtBMC.
> 
> **Future Plans:** We are planning to add a toggle in the VirtualMachineBMC CRD to disable IPMI functionality by default. 
> 
> **Recommendation:** For production use, we recommend using the [Redfish API](redfish-guide.md) which provides better security, proper authentication, and modern RESTful access.

## Accessing IPMI

### Run IPMI Client in Pod (Recommended)

Since IPMI uses UDP and requires cluster network access, run an IPMI client pod:

```bash
kubectl run -it --rm ipmitool \
    --image=mikeynap/ipmitool \
    --restart=Never \
    --command -- /bin/sh
```

Inside the pod, use the service DNS name:

```bash
ipmitool -I lan -U admin -P password -H <serviceName>.<serviceNamespace>.svc.cluster.local power <command>
```

## Power Management

### Power Status

```bash
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local power status
```

#### **Output:**
- `Chassis Power is on` - VM is running
- `Chassis Power is off` - VM is stopped

### Power On

```bash
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local power on

```

### Power Off (Graceful)

```bash
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local power off

```

Sends ACPI shutdown signal. VM must support ACPI for graceful shutdown.

### Power Cycle

```bash
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local power cycle
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
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local chassis bootdev pxe
```

### Set Boot to Disk

```bash
ipmitool -I lan -U admin -P password -H testvm-virtbmc.default.svc.cluster.local chassis bootdev disk
```
### Supported Boot Devices

| Device | Description |
|--------|-------------|
| `pxe` | Network boot (PXE) |
| `disk` | Boot from disk |

## Next Steps

- Read the [Redfish Guide](redfish-guide.md) for RESTful API access

