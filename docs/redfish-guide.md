# Redfish Guide

This guide covers using the Redfish RESTful API with KubeVirtBMC for managing virtual machines.

## Overview

Redfish is a modern RESTful API standard for systems management. KubeVirtBMC implements Redfish version 1.16.1.

**Service Endpoint:**
```
http://<vm-name>-virtbmc.<namespace>.svc.cluster.local/redfish/v1
```

**Example:**
```
http://testvm-virtbmc.default.svc.cluster.local/redfish/v1
```

## Accessing Redfish

### Run Redfish Client in Pod (Recommended)

Since Redfish requires cluster network access, run a Redfish client pod:

```bash
kubectl run -it --rm redfish-client \
    --image=curlimages/curl:latest \
    --restart=Never \
    --command -- /bin/sh
```

Inside the pod, use the service DNS name:

```bash
curl http://<vm-name>-virtbmc.<namespace>.svc.cluster.local/redfish/v1
```

## Authentication

Redfish supports two authentication methods:

1. **Session-based authentication** (recommended) - Create a session to obtain a token
2. **Basic authentication** - Use HTTP Basic Auth directly

> NOTE: Redfish uses a backend server that validates credentials from the Kubernetes Secret. Unlike IPMI, Redfish supports proper session management and token-based authentication. Credentials are read from the Secret specified in the VirtualMachineBMC resource.

### Basic Authentication

You can use HTTP Basic Auth directly without creating a session:

```bash
curl -u admin:admin123 \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1
```

Or with explicit Basic Auth header:

```bash
curl -H "Authorization: Basic $(echo -n 'admin:admin123' | base64)" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1
```

### Session-Based Authentication

Create a session to obtain an authentication token for better security and session management.

## Create Session

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/SessionService/Sessions \
    -d '{"UserName":"admin","Password":"admin123"}'
```

### Extract Token

```bash
TOKEN=$(curl -s -i -X POST \
    -H "Content-Type: application/json" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/SessionService/Sessions \
    -d '{"UserName":"admin","Password":"admin123"}' \
    | grep -i "X-Auth-Token" | cut -d' ' -f2 | tr -d '\r')
```

### Use Token

Include the token in the `X-Auth-Token` header for all authenticated requests:

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1
```

## Service Discovery

### Service Root

```bash
curl http://testvm-virtbmc.default.svc.cluster.local/redfish/v1
```

Returns available resources including Systems, Managers, and SessionService.

## Power Management

### Get System Status

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1
```

### Power On

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1/Actions/ComputerSystem.Reset \
    -d '{"ResetType":"On"}'
```

### Graceful Shutdown

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1/Actions/ComputerSystem.Reset \
    -d '{"ResetType":"GracefulShutdown"}'
```

### Force Off

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1/Actions/ComputerSystem.Reset \
    -d '{"ResetType":"ForceOff"}'
```

### Graceful Restart

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1/Actions/ComputerSystem.Reset \
    -d '{"ResetType":"GracefulRestart"}'
```

### Force Restart

```bash
curl -i -X POST \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1/Actions/ComputerSystem.Reset \
    -d '{"ResetType":"ForceRestart"}'
```

### Reset Types

| ResetType | Description | Graceful |
|-----------|-------------|----------|
| `On` | Power on | N/A |
| `GracefulShutdown` | Shutdown with ACPI | Yes |
| `ForceOff` | Immediate power off | No |
| `GracefulRestart` | Restart with ACPI | Yes |
| `ForceRestart` | Immediate restart | No |

## Boot Configuration

### Get Current Boot Configuration

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    | jq '.Boot'
```

### Set Boot to PXE (One-time)

```bash
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Pxe",
            "BootSourceOverrideEnabled": "Once"
        }
    }'
```

### Set Boot to PXE (Continuous)

```bash
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Pxe",
            "BootSourceOverrideEnabled": "Continuous"
        }
    }'
```

### Set Boot to Disk

```bash
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Hdd",
            "BootSourceOverrideEnabled": "Once"
        }
    }'
```

### Set Boot Mode

```bash
# UEFI mode
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{"Boot": {"BootSourceOverrideMode": "UEFI"}}'

# Legacy mode
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{"Boot": {"BootSourceOverrideMode": "Legacy"}}'
```

### Boot Configuration Options

| Option | Values | Description |
|--------|--------|-------------|
| `BootSourceOverrideTarget` | `Pxe`, `Hdd`, `Cd` | Boot device |
| `BootSourceOverrideEnabled` | `Once`, `Continuous`, `Disabled` | Override behavior |
| `BootSourceOverrideMode` | `Legacy`, `UEFI` | Boot mode |

## System Information

### Get System Details

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
```

### Get Manager Information

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Managers/BMC
```

## Next Steps

- Read the [Virtual Media Guide](virtual-media.md) for virtual media and ISO management
