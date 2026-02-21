

# KubeVirtBMC Documentation

Welcome to the **KubeVirtBMC documentation**.
This guide provides everything you need to install, configure, and operate KubeVirtBMC for managing virtual machines on Kubernetes clusters using industry-standard out-of-band management protocols.


## What is KubeVirtBMC?

`KubeVirtBMC` enables out-of-band management for Kubernetes-based virtual machines using:

* `IPMI (Intelligent Platform Management Interface)` - Traditional BMC protocol
* `Redfish` - Modern RESTful API for systems management

It allows infrastructure teams to manage VMs in Kubernetes environments using existing provisioning and management tooling that already supports IPMI or Redfish.

## Features

KubeVirtBMC provides:

* IPMI support for power management and boot configuration
* Redfish API (v1.16.1 compliant)
* Virtual media support for ISO image attachment
* Designed for integration with existing provisioning pipelines

## Quick Links

* [GitHub Repository](https://github.com/kubevirtbmc/kubevirtbmc)
* [Helm Chart](https://charts.zespre.com/)

## Next Steps

To get started:

1. Read the [Introduction](introduction.md) to understand more about it.
2. Follow the [QuickStart Guide](getting-started.md) to install and deploy.

## Contributing

We welcome contributions from the community! Whether you're fixing bugs, adding features, improving documentation, or sharing ideas, your contributions are always welcome. Please feel free to open issues, submit pull requests, or reach out to the maintainers.

**Note:** This documentation is continuously updated. If you encounter issues or have suggestions, please open an issue on [GitHub](https://github.com/kubevirtbmc/kubevirtbmc).
