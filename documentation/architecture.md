# Architecture

This document describes the architecture and design of KubeVirtBMC.

## System Architecture

![KubeVirtBMC Architecture](assets/css/kubevirtbmc_architecture.png)

## Components

### virtbmc-controller

The virtbmc-controller is a Kubernetes controller manager that watches VirtualMachineBMC Custom Resources and reconciles their desired state. It creates and manages virtbmc Pods and Services, updates VirtualMachineBMC status with the current state of managed resources, and works with the webhook server to validate resource specifications.

### virtbmc

The virtbmc is the BMC emulator that runs as a Pod for each VirtualMachineBMC resource. It implements IPMI protocol on UDP port 623 and Redfish API on HTTP port 80, translating BMC commands into Kubernetes API calls to manage VirtualMachine resources. It handles authentication, session management, and virtual media operations through CDI integration.

### Webhook Server

The Webhook Server provides admission control for VirtualMachineBMC resources through validating and mutating webhooks. It ensures that referenced VirtualMachine and Secret resources exist, validates resource specifications, and can mutate resources to set default values before the controller processes them.


### Generated Resources

For each VirtualMachineBMC, the controller automatically creates:

1. **Service** (ClusterIP): Exposes virtbmc Pod on ports 623 (UDP) for IPMI and 80 (TCP) for Redfish
2. **Pod**: Runs the virtbmc BMC emulator
3. **ServiceAccount**: Created in the same namespace as the VirtualMachineBMC resource
4. **RoleBinding**: Grants necessary RBAC permissions to the ServiceAccount for managing VirtualMachine resource

## Next Steps

- Read the [API Reference](api-reference.md) for detailed resource specifications
- Check the [Configuration Guide](configuration.md) for deployment options
