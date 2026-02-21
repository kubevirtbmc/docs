# Introduction to KubeVirtBMC

## Overview

KubeVirtBMC is an open-source project that provides out-of-band management capabilities for [Kubevirt](https://kubevirt.io/user-guide/) virtual machines running on Kubernetes clusters. It implements industry-standard Baseboard Management Controller (BMC) protocols - `IPMI` and `Redfish` to enable remote management of KubeVirt virtual machines.

## What Problem Does KubeVirtBMC Solve?

Traditional bare-metal provisioning and management tools (like [Tinkerbell](https://github.com/tinkerbell/tink) and [Seeder](https://github.com/harvester/seeder)) expect to interact with physical servers through BMC interfaces using IPMI or Redfish protocols. However, when virtualizing infrastructure on Kubernetes with KubeVirt, these virtual machines don't have physical BMCs.

KubeVirtBMC bridges this gap by:

1. **Providing virtual BMCs** for KubeVirt virtual machines
2. **Emulating IPMI and Redfish protocols** that provisioning tools understand
3. **Translating BMC commands** into Kubevirt API calls to manage VMs


This allows you to use the same provisioning workflows and tools for both physical and virtual infrastructure.

## Comparison with VirtualBMC

KubeVirtBMC was inspired by [VirtualBMC](https://opendev.org/openstack/virtualbmc) but differs in key ways:

| Aspect | VirtualBMC | KubeVirtBMC |
|--------|-----------|-------------|
| **Target Platform** | OpenStack/libvirt | Kubernetes/KubeVirt |
| **API** | libvirt API | Kubevirt API |
| **Deployment** | Standalone process | Kubernetes-native (Deployment) |
| **Management** | Manual process management | Kubernetes controller |
| **Scaling** | Manual | Automatic via Kubernetes |

## Project History

KubeVirtBMC was born during [SUSE Hack Week 23](https://hackweek.opensuse.org/23/projects/extending-kubevirtbmcs-capability-by-adding-redfish-support) and has evolved through multiple hack weeks.

## Next Steps

- Read the [Getting Started Guide](getting-started.md) to install KubeVirtBMC
- Explore the [Architecture](architecture.md) documentation

