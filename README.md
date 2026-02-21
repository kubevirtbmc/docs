# KubeVirtBMC Documentation

This repository contains the documentation for **KubeVirtBMC** — out-of-band management for virtual machines on Kubernetes using IPMI and Redfish. The docs cover installation, configuration, architecture, API reference, and user guides (IPMI, Redfish, virtual media).

The site is built with [Zensical](https://zensical.org/) using the `zensical.toml` configuration.

## Serving the docs locally

From the repository root:

```bash
make zensical-serve
```

This creates a virtual environment (if needed), installs Zensical, and starts the dev server at **http://127.0.0.1:8000** with live reload.

To remove the virtual environment and generated site:

```bash
make zensical-cleanup
```

## Project links

- [KubeVirtBMC on GitHub](https://github.com/kubevirtbmc/kubevirtbmc)
