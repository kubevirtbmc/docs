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

## Versioning

This site publishes two versions so documentation PRs don't have to wait on a
KubeVirtBMC release to merge:

- **`dev`** — deployed automatically on every push to `main`. Use this for
  docs about unreleased/in-progress features.
- **`stable`** (default) — deployed by pushing a version tag (e.g. `v0.3.0`),
  which snapshots `main` at that point and promotes it to the version served
  at the site root.

Deployment is handled by [mike](https://github.com/squidfunk/mike) (a
Zensical-compatible fork) via `.github/workflows/deploy-docs.yml`. To preview
versioning locally:

```bash
pip install -r requirements.txt
mike deploy --update-aliases dev
mike serve
```

## Project links

- [KubeVirtBMC on GitHub](https://github.com/kubevirtbmc/kubevirtbmc)
