# docs
The documentation for KubeVirtBMC
# KubeVirtBMC Documentation

This repository contains the documentation for **KubeVirtBMC** — out-of-band management for virtual machines on Kubernetes using IPMI and Redfish. The docs cover installation, configuration, architecture, API reference, and user guides (IPMI, Redfish, virtual media).

The site is built with [MkDocs](https://www.mkdocs.org/) and the Material theme.

## Serving the docs locally

From the repository root, run:

```bash
make mkdocs-serve
```

This will create a virtual environment (if needed), install dependencies, and start the MkDocs development server with live reload. Open **http://127.0.0.1:8000** in your browser; changes to the markdown files will reload automatically.

To remove the virtual environment and generated site:

```bash
make mkdocs-cleanup
```

## Project links

- [KubeVirtBMC on GitHub](https://github.com/kubevirtbmc/kubevirtbmc)