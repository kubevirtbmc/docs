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
kubectl run redfish-client \
    --image=alpine \
    --restart=Never \
    --command -- sleep 9999999
```

```bash
kubectl exec -it redfish-client -- /bin/sh
```

Once inside the pod, install `curl` and `jq`:

```bash
apk add --no-cache curl jq
```

Inside the pod, use the service DNS name:

```bash
curl http://<vm-name>-virtbmc.<namespace>.svc.cluster.local/redfish/v1
```

### Cleanup

Once finished and exited, delete the pod: 

```bash
kubectl delete pod redfish-client
```

## Authentication

Redfish supports two authentication methods:

1. **Session-based authentication** (recommended) - Create a session to obtain a token
2. **Basic authentication** - Use HTTP Basic Auth directly

!!! note
    Redfish uses a backend server that validates credentials from the Kubernetes Secret. Unlike IPMI, Redfish supports proper session management and token-based authentication. Credentials are read from the Secret specified in the VirtualMachineBMC resource.

### Basic Authentication

You can use HTTP Basic Auth directly without creating a session:

```bash
curl -u admin:admin123 \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 | jq
```

Or with explicit Basic Auth header:

```bash
curl -H "Authorization: Basic $(echo -n 'admin:admin123' | base64)" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 | jq
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
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 | jq
```

## Service Discovery

### Service Root

```bash
curl http://testvm-virtbmc.default.svc.cluster.local/redfish/v1 | jq
```

Returns available resources including Systems, Managers, and SessionService.

## Power Management

### Get System Status

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 | jq
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

## Transitional VM State Handling (Redfish Retry Signal)

For power transition requests (e.g., `ResetType: On/Off/ForceRestart`), `virtbmc` must not treat KubeVirt asynchronous lifecycle gaps as a guaranteed success.

Current behavior:

- The agent uses **Try-Then-Verify** to avoid swallowing ambiguous “power already in desired state” situations.
- If the VM is still in a transitional state where the operation is **not yet reflected** in the final VM power state, `virtbmc` returns a retryable Redfish signal:
  - HTTP status: **500**
  - Error message pattern: **iLO / InvalidOperationForSystemState** (power transition in progress)

Clients that implement “retry on iLO InvalidOperationForSystemState” (notably sushy/Ironic) can re-issue the power action until the VM state converges.

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
# One-time
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

# Continuous
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Hdd",
            "BootSourceOverrideEnabled": "Continuous"
        }
    }'
```

### Set Boot to CD-ROM

```bash
# One-time
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Cd",
            "BootSourceOverrideEnabled": "Once"
        }
    }'

# Continuous
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Cd",
            "BootSourceOverrideEnabled": "Continuous"
        }
    }'
```

### Disable Boot Override

Clear any pending boot device override and restore the VM's default boot order:

```bash
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideEnabled": "Disabled"
        }
    }'
```

### Set Boot Device with Firmware Mode

You can combine boot device override and firmware mode (UEFI/Legacy) in a single request:

```bash
# PXE one-shot + UEFI
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Pxe",
            "BootSourceOverrideEnabled": "Once",
            "BootSourceOverrideMode": "UEFI"
        }
    }'

# HDD continuous + Legacy
curl -i -X PATCH \
    -H "Content-Type: application/json" \
    -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    -d '{
        "Boot": {
            "BootSourceOverrideTarget": "Hdd",
            "BootSourceOverrideEnabled": "Continuous",
            "BootSourceOverrideMode": "Legacy"
        }
    }'
```

### Set Boot Mode (Firmware Only)

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

### One-Shot Boot and In-Guest Reboot

When using `"Once"` for `BootSourceOverrideEnabled`, KubeVirtBMC writes the boot order override to the KubeVirt VirtualMachine's template, and it takes effect the next time a VirtualMachineInstance (VMI) is created. As soon as a new VMI appears, KubeVirtBMC restores the original boot order in the template, completing the one-shot.

KubeVirt does not live-apply template changes to a running VMI, and by default an in-guest reboot does not recreate the VMI either — the guest simply restarts with the configuration the VMI was created with. This has two consequences:

- A one-shot override set on a running VM is ignored by an in-guest reboot: the override only exists in the template, so the VM boots from its default devices. Only a BMC-initiated reset or power cycle applies it.
- Once the VM has booted from the override device, an in-guest reboot (e.g., an OS installer rebooting when it finishes) boots from the override device again, because the VMI still carries the boot order it was created with — even though KubeVirtBMC has already restored the template.

Setting the KubeVirt VirtualMachine's `rebootPolicy` to `Terminate` makes guest reboots terminate the VMI, so the VM controller recreates it from the current template and in-guest reboots behave the same as BMC-initiated resets.

!!! note "KubeVirt version requirement"

    The `rebootPolicy` field was introduced in KubeVirt 1.8.0 ([kubevirt/kubevirt#16579](https://github.com/kubevirt/kubevirt/pull/16579)). It requires the `RebootPolicy` feature gate to be enabled in the KubeVirt configuration.

**Example VirtualMachine with rebootPolicy:**

```yaml
apiVersion: kubevirt.io/v1
kind: VirtualMachine
metadata:
  name: testvm
spec:
  runStrategy: Always
  template:
    spec:
      domain:
        rebootPolicy: Terminate  # Terminate VMI on guest reboot
        devices:
          disks:
          - name: containerdisk
            disk:
              bus: virtio
        resources:
          requests:
            memory: 64Mi
      volumes:
      - name: containerdisk
        containerDisk:
          image: quay.io/kubevirt/cirros-container-disk-demo
```

!!! warning

    With `rebootPolicy: Terminate`, every in-guest reboot becomes a full VMI recreation, which takes noticeably longer than a normal guest reboot — the virt-launcher pod is recreated and the guest boots from scratch (seconds to minutes, depending on scheduling). KubeVirtBMC itself is unaffected and keeps serving IPMI/Redfish requests, but while the new VMI is starting the VM reports as not ready, so power status reads (`chassis power status`, Redfish `PowerState`) report the host as off. Enable this only when you need boot order changes to apply across in-guest reboots.

### Verify RebootPolicy Feature Gate

Check that the `RebootPolicy` feature gate is enabled:

```bash
kubectl get kubevirt kubevirt -n kubevirt -o yaml | grep RebootPolicy
```

If it is not enabled, patch the KubeVirt resource:

```bash
kubectl patch kubevirt kubevirt -n kubevirt --type merge -p \
  '{"spec":{"configuration":{"developerConfiguration":{"featureGates":["RebootPolicy"]}}}}'
```

## System Information

### Get System Details

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 | jq
```

The system resource exposes the VM identity so clients can correlate the BMC with the KubeVirt VirtualMachine:

```bash
curl -s -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Systems/1 \
    | jq '{Manufacturer, Model, Name, SerialNumber, SystemType}'
```

```json
{
  "Manufacturer": "KubeVirt",
  "Model": "KubeVirt",
  "Name": "default/testvm",
  "SerialNumber": "default/testvm",
  "SystemType": "Virtual"
}
```

`Name` and `SerialNumber` carry the VM identity in `<namespace>/<vm-name>` form (untruncated; the [IPMI FRU](ipmi-guide.md#fru-inventory) equivalent is limited to 63 bytes).

### Get Manager Information

```bash
curl -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Managers/BMC | jq
```

The manager's `FirmwareVersion` reports the Git commit SHA of the virtbmc build — the same value exposed as the FRU Product Version over IPMI:

```bash
curl -s -H "X-Auth-Token: $TOKEN" \
    http://testvm-virtbmc.default.svc.cluster.local/redfish/v1/Managers/BMC \
    | jq '{Model, FirmwareVersion}'
```

```json
{
  "Model": "KubeVirtBMC",
  "FirmwareVersion": "c935d5d2d6b11b345154916e339088c4a61e84ba"
}
```

## Next Steps

- Read the [Virtual Media Guide](virtual-media.md) for virtual media and ISO management
