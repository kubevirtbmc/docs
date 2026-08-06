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

## Deploy previews

Pull requests get a live, rendered preview build via [Netlify](https://docs.netlify.com/deploy/deploy-types/deploy-previews/), driven by `netlify.toml` (`zensical build`, publishing the `site` directory). This lets reviewers see the actual Zensical-rendered output instead of relying on the raw Markdown diff. Production continues to deploy to GitHub Pages via `.github/workflows/deploy-pages.yml`.

## Project links

- [KubeVirtBMC on GitHub](https://github.com/kubevirtbmc/kubevirtbmc)
