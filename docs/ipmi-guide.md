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
    --image=kubevirtbmc/ipmitool \
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

## Transitional VM State Handling (IPMI Retry Signal)

When KubeVirt is between asynchronous lifecycle steps (e.g., the VM/VMI is still starting or stopping), `virtbmc` must not treat those transitional windows as guaranteed success.

Current behavior:

- The agent uses a **Try-Then-Verify** approach to avoid swallowing ambiguous “already running/already stopped” situations.
- If the VM is still transitional and the requested operation is **not yet reflected** in the final VM power state, `virtbmc` returns a **retryable IPMI error**:
  - Completion code: **Node Busy (0xC0)**

Clients that implement “retry on Node Busy” (notably Ironic) can re-issue the power action until the VM state converges.

## Device and Inventory Information

### BMC Device Info

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" mc info
```

Example output:

```
Device ID                 : 32
Device Revision           : 1
Firmware Revision         : 1.00
IPMI Version              : 0.2
Manufacturer ID           : 0
Manufacturer Name         : Unknown
Product ID                : 0 (0x0000)
Product Name              : Unknown (0x00)
Device Available          : yes
Provides Device SDRs      : no
Additional Device Support :
    SDR Repository Device
    FRU Inventory Device
```

`Additional Device Support` advertises the **SDR Repository Device** and **FRU Inventory Device** capabilities.

### FRU Inventory

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" fru list
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" fru print 0
```

Example output (identical for both commands, as there is a single builtin FRU device):

```
FRU Device Description : Builtin FRU Device (ID 0)
 Product Manufacturer  : KubeVirt
 Product Name          : KubeVirtBMC
 Product Version       : c935d5d2d6b11b345154916e339088c4a61e84ba
 Product Serial        : default/testvm
```

| Field | Value |
|-------|-------|
| Product Manufacturer | `KubeVirt` |
| Product Name | `KubeVirtBMC` |
| Product Version | Git commit SHA of the virtbmc build |
| Product Serial | VM identity in `<namespace>/<vm-name>` form |

!!! note "FRU field length limit"

    FRU fields are truncated to 63 bytes per the IPMI specification. Use the [Redfish API](redfish-guide.md#system-information) to read the full, untruncated VM identity (`SerialNumber`).

## Boot Device Configuration

### Set Boot to PXE

```bash
# One-shot (default)
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe

# Persistent
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe options=persistent

# One-shot + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe options=efiboot

# Persistent + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev pxe options=persistent,efiboot
```

### Set Boot to Disk

```bash
# One-shot (default)
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk

# Persistent
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk options=persistent

# One-shot + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk options=efiboot

# Persistent + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev disk options=persistent,efiboot
```

### Set Boot to CD-ROM

```bash
# One-shot (default)
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom

# Persistent
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom options=persistent

# One-shot + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom options=efiboot

# Persistent + UEFI
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev cdrom options=persistent,efiboot
```

### Supported Boot Devices

| Device | Description |
|--------|-------------|
| `pxe` | Network boot (PXE) |
| `disk` | Boot from disk |
| `cdrom` | Boot from CD-ROM |

### Boot Options

`chassis bootdev` supports the following `options=` flags:

| Option | Description |
|--------|-------------|
| *(none)* | One-shot override (default). The device is used for a single boot, then the VM reverts to its default boot order. |
| `persistent` | Persistent override. The boot device override persists across multiple boots. Equivalent to Redfish `BootSourceOverrideEnabled: "Continuous"`. |
| `efiboot` | UEFI firmware boot. Sets the boot mode to UEFI. Omit for legacy BIOS mode. |

Multiple options can be combined with commas, e.g. `options=persistent,efiboot`.

!!! warning "ipmitool version requirement for combined options"

    When combining `persistent` with `efiboot` (e.g. `options=persistent,efiboot`), make sure the ipmitool client is **v1.8.19 or later** (check with `ipmitool -V`). Older versions have a bug in parsing multiple `options=` values ([ipmitool/ipmitool#163](https://github.com/ipmitool/ipmitool/issues/163)): only one of the combined flags is sent to the BMC. For example, a `persistent,efiboot` request may be sent without the persistent flag, so the override takes effect as one-shot instead of persistent (`status.bootOverride.mode` shows `Oneshot` instead of `Persistent`).

    On an older ipmitool, set the boot flags with a `raw` command instead. This is the same workaround used by [OpenStack Ironic](https://bugs.launchpad.net/ironic/+bug/1611306) and works with any ipmitool version. It sends a Set System Boot Options request (NetFn `0x00`, Cmd `0x08`) for the boot flags parameter `0x05` (see Table 28-14 "Boot Option Parameters" in the IPMI v2.0 specification):

    ```bash
    # data byte 1: 0xe0 = boot flags valid + persistent + EFI (use 0xa0 for one-shot + EFI)
    # data byte 2: boot device selector — pxe=0x04, disk=0x08, cdrom=0x14
    ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" raw 0x00 0x08 0x05 0xe0 0x04 0x00 0x00 0x00
    ```

### Read Back Boot Flags

`chassis bootparam get 5` (Get System Boot Options, boot flags parameter — see Table 28-14 "Boot Option Parameters" in the IPMI v2.0 specification) reads back the current boot device override:

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootparam get 5
```

This produces output similar to:

```
Boot parameter version: 1
Boot parameter 5 is valid/unlocked
Boot parameter data: 8000040000
 Boot Flags :
   - Boot Flag Valid
   - Options apply to only next boot
   - BIOS PC Compatible (legacy) boot
   - Force PXE
```


### Clear Boot Override

Clear any pending boot device override and restore the VM's default boot order:

```bash
ipmitool -I lanplus -U "$USERNAME" -P "$PASSWORD" -H "$HOSTNAME" chassis bootdev none
```

### One-Shot Boot and In-Guest Reboot

When using one-shot boot override (the default without `options=persistent`), the VM boots from the specified device once, then KubeVirtBMC restores the VM's default boot order. This restore is tied to VMI recreation: by default, an in-guest reboot restarts the guest inside the existing VirtualMachineInstance (VMI), which keeps the boot order it was created with. So if the guest OS reboots itself (e.g., after completing an OS installation), the VM boots from the override device again instead of the default boot order — and a one-shot override set on a running VM is ignored entirely by an in-guest reboot, since it only exists in the VM template.

Setting the KubeVirt VirtualMachine's `rebootPolicy` to `Terminate` makes guest reboots terminate the VMI, so the VM controller recreates it from the current template and in-guest reboots behave the same as BMC-initiated power actions.

!!! note "KubeVirt version requirement"

    The `rebootPolicy` field was introduced in KubeVirt 1.8.0 ([kubevirt/kubevirt#16579](https://github.com/kubevirt/kubevirt/pull/16579)). It requires the `RebootPolicy` feature gate to be enabled in the KubeVirt configuration. See the [Redfish Guide](redfish-guide.md#one-shot-boot-and-in-guest-reboot) for a complete example.

## Next Steps

- Read the [Redfish Guide](redfish-guide.md) for RESTful API access
